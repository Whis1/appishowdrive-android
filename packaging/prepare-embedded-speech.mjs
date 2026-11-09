import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {Readable} from 'node:stream';
import {pipeline} from 'node:stream/promises';
import {fileURLToPath} from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const target = path.join(root, 'android/app/src/main/assets/speech/kokoro.litertlm');
const original = path.join(root, '.dart_tool/embedded-speech/original.litertlm');
const expected = 'e7b931ee5d4b7104012a838c9eee240d19ea69cb3ca269041a3274f83dbb7fa1';
async function hash(file) {
  const digest = crypto.createHash('sha256');
  for await (const chunk of fs.createReadStream(file)) digest.update(chunk);
  return digest.digest('hex');
}
if (!fs.existsSync(original) || await hash(original) !== expected) {
  fs.mkdirSync(path.dirname(original), {recursive: true});
  const response = await fetch('https://huggingface.co/litert-community/Kokoro-82M/resolve/33ad69fec6c4d9eb10a547aaf9a8c63e7c446a56/kokoro_int8_fp16.litertlm');
  if (!response.ok) throw Error(`Model download failed: ${response.status}`);
  await pipeline(Readable.fromWeb(response.body), fs.createWriteStream(original + '.partial'));
  if (await hash(original + '.partial') !== expected) throw Error('Incorrect bundled voice model SHA256');
  fs.renameSync(original + '.partial', original);
}
// Create genuine blended speaker embeddings, preserving the Italian phonemizer.
// All acoustic/vocoder weights remain byte-identical. No pitch/speed substitutions.
const profiles = [
  ['af_heart','if_heart','if_sara'], ['bf_emma','if_emma','if_sara'],
  ['ef_dora','if_dora','if_sara'], ['pf_dora','if_luna','if_sara'],
  ['am_adam','im_adam','im_nicola'], ['bm_george','im_george','im_nicola'],
  ['em_alex','im_alex','im_nicola'], ['pm_alex','im_luca','im_nicola'],
];
const input = fs.openSync(original, 'r');
const header = Buffer.alloc(16384); fs.readSync(input, header, 0, header.length, 0);
const u32 = p => header.readUInt32LE(p);
const field = (table,n) => {
  const v = table - header.readInt32LE(table), entry = v + 4 + n * 2;
  return entry < v + header.readUInt16LE(v) && header.readUInt16LE(entry) ? table + header.readUInt16LE(entry) : 0;
};
const ref = p => p + u32(p);
const string = p => { const start=ref(p); return header.toString('utf8',start+4,start+4+u32(start)); };
const rootTable = 32 + u32(32), metadata = ref(field(rootTable,1));
const vector = ref(field(metadata,0)), sections = new Map();
for (let i=0; i<u32(vector); i++) {
  const table=ref(vector+4+i*4), items=ref(field(table,0));
  for (let j=0; j<u32(items); j++) {
    const kv=ref(items+4+j*4);
    if (string(field(kv,0)) !== 'name' || header[field(kv,1)] !== 9) continue;
    const valueTable=ref(field(kv,2)), nameField=field(valueTable,0);
    sections.set(string(nameField), {nameOffset: ref(nameField)+4, begin:Number(header.readBigUInt64LE(field(table,1))), end:Number(header.readBigUInt64LE(field(table,2)))});
  }
}
fs.mkdirSync(path.dirname(target), {recursive:true});
fs.copyFileSync(original, target + '.partial');
const output = fs.openSync(target + '.partial', 'r+');
for (const [source,name,base] of profiles) {
  const a=sections.get(source), b=sections.get(base);
  if (!a || !b || source.length !== name.length || a.end-a.begin !== 522240 || b.end-b.begin !== 522240) throw Error('Unexpected voice-bank structure');
  const other=Buffer.alloc(522240), italian=Buffer.alloc(522240), blend=Buffer.alloc(522240);
  fs.readSync(input,other,0,other.length,a.begin); fs.readSync(input,italian,0,italian.length,b.begin);
  for(let i=0;i<blend.length;i+=4) {
    const value = italian.readFloatLE(i)*.6+other.readFloatLE(i)*.4;
    if(!Number.isFinite(value)) throw Error('Invalid voice embedding');
    blend.writeFloatLE(value,i);
  }
  fs.writeSync(output,blend,0,blend.length,a.begin);
  header.write(name,a.nameOffset,source.length,'utf8');
}
fs.writeSync(output,header,0,header.length,0);
fs.closeSync(input); fs.closeSync(output);
if (await hash(target + '.partial') !== '9cffd6930329144d76f35d5bf1c6f411752e48a294e6618ca903987aacb75fe5') throw Error('Derived Italian model SHA256 does not match');
fs.renameSync(target + '.partial',target);
console.log(JSON.stringify({model:'Kokoro Italian profiles v1',size:fs.statSync(target).size,sha256:await hash(target),license:'Apache-2.0',italianBaseWeight:.6,profiles:profiles.map(p=>p[1])}));
