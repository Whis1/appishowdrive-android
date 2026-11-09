import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {AUDIO_SOURCE_FILES,audioSourceFingerprint,sha256,assertVerifiedAndroidAudio} from '../verify-audio-evidence.mjs';

function fixture(t) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'ishowdrive-audio-proof-'));
  assert.ok(path.resolve(root).startsWith(path.resolve(os.tmpdir()) + path.sep + 'ishowdrive-audio-proof-'));
  t.after(() => fs.rmSync(root,{recursive:true,force:true}));
  for (const file of AUDIO_SOURCE_FILES) {
    fs.mkdirSync(path.dirname(path.join(root,file)),{recursive:true});
    fs.writeFileSync(path.join(root,file),'fixture '+file);
  }
  const proof = {sourceSha256:audioSourceFingerprint(root),passed:true,
    scene:{realAndroid:true,speechStartAt:1000,speechEndAt:3000,videoPausedDuringSpeech:false},
    duringSpeech:{windows:100,pilotPresentFraction:1,longestPilotGapMs:0}};
  fs.mkdirSync(path.join(root,'qa-artifacts'));
  const bytes = Buffer.from(JSON.stringify(proof));
  fs.writeFileSync(path.join(root,'qa-artifacts/audio-continuity-report.json'),bytes);
  const verification = {audioEvidence:{schema:1,sourceSha256:proof.sourceSha256,reportSha256:sha256(bytes)}};
  return {root,verification};
}

test('accepts measured audio evidence bound to the current source files',t=>{
  const {root,verification}=fixture(t);
  assert.equal(assertVerifiedAndroidAudio(root,verification).passed,true);
});
test('rejects the former unbound verification report',t=>{
  const {root}=fixture(t);
  assert.throws(()=>assertVerifiedAndroidAudio(root,{realAndroidAudioTest:true}),/Fresh audio evidence/);
});
test('requires a new audio run after app version or playback code changes',t=>{
  for(const file of ['pubspec.yaml','lib/models/tts.dart']) {
    const {root,verification}=fixture(t);
    fs.appendFileSync(path.join(root,file),' changed');
    assert.throws(()=>assertVerifiedAndroidAudio(root,verification),/sources changed/);
  }
});
test('rejects a replaced measurement even when its passing flag remains true',t=>{
  const {root,verification}=fixture(t);
  fs.appendFileSync(path.join(root,'qa-artifacts/audio-continuity-report.json'),'\n');
  assert.throws(()=>assertVerifiedAndroidAudio(root,verification),/report changed/);
});
