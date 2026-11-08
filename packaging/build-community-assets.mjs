import fs from 'node:fs/promises';import path from 'node:path';import {createRequire} from 'node:module';
const require=createRequire(path.join(process.env.USERPROFILE,'.cache/codex-runtimes/codex-primary-runtime/dependencies/node/package.json')),sharp=require('sharp');
const root=process.cwd(),source=root+'/assets/appishowdrive-original.png',res=root+'/android/app/src/main/res';
for(const [density,scale,legacy]of [['ldpi',.75,36],['mdpi',1,48],['hdpi',1.5,72],['xhdpi',2,96],['xxhdpi',3,144],['xxxhdpi',4,192]]){
 const dir=res+'/mipmap-'+density;await fs.mkdir(dir,{recursive:true});await sharp(source).resize(legacy,legacy,{fit:'fill',kernel:'lanczos3'}).png().toFile(dir+'/ic_launcher.png');
 const size=Math.round(108*scale),safe=Math.round(76*scale),pad=Math.floor((size-safe)/2);
 const image=await sharp(source).resize(safe,safe,{fit:'fill',kernel:'lanczos3'}).png().toBuffer();
 await sharp({create:{width:size,height:size,channels:4,background:'#00000000'}}).composite([{input:image,left:pad,top:pad}]).png().toFile(dir+'/ic_launcher_foreground.png');
 await sharp(source).resize(size,size,{fit:'fill',kernel:'lanczos3'}).png().toFile(dir+'/ic_launcher_background.png');
}
const fonts=root+'/assets/fonts';await fs.mkdir(fonts,{recursive:true});
for(const [family,slug]of [['Manrope','manrope'],['SpaceGrotesk','spacegrotesk']]){
 const response=await fetch(`https://raw.githubusercontent.com/google/fonts/main/ofl/${slug}/${family}%5Bwght%5D.ttf`);if(!response.ok)throw Error(family+' '+response.status);await fs.writeFile(fonts+'/'+family+'.ttf',Buffer.from(await response.arrayBuffer()));
 const license=await fetch(`https://raw.githubusercontent.com/google/fonts/main/ofl/${slug}/OFL.txt`);if(!license.ok)throw Error('Missing font license');await fs.writeFile(fonts+'/'+family+'-OFL.txt',await license.text());
}
console.log('Icone senza cornice nera e font locali OFL generati.');
