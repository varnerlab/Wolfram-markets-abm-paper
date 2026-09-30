// Native, editable one-slide PowerPoint companion to inventory-pitch.tex.
// Uses the supplied Codex artifact runtime. See ../README.md for invocation.
import fs from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { fileURLToPath, pathToFileURL } from 'node:url';

const workspaceDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const { RUNTIME_NODE_MODULES, RUNTIME_PYTHON, PRESENTATION_SKILL_DIR } = process.env;
if (![RUNTIME_NODE_MODULES, RUNTIME_PYTHON, PRESENTATION_SKILL_DIR].every(p => p && path.isAbsolute(p))) {
  throw new Error('Set absolute RUNTIME_NODE_MODULES, RUNTIME_PYTHON, and PRESENTATION_SKILL_DIR.');
}
const requireRuntime = createRequire(path.join(RUNTIME_NODE_MODULES, '__runtime__.cjs'));
const { Presentation, PresentationFile } = await import(pathToFileURL(requireRuntime.resolve('@oai/artifact-tool')));
const { finalizePresentation } = await import(pathToFileURL(path.join(PRESENTATION_SKILL_DIR, 'container_tools/artifact_tool_utils.mjs')));
const buildDir = path.join(workspaceDir, 'build/pitch');
await fs.mkdir(buildDir, { recursive: true });
await fs.mkdir(path.join(workspaceDir, 'output/pptx'), { recursive: true });
const fontPolicy = { basis: 'design', families: ['Helvetica Neue'] };
const presentation = Presentation.create({ slideSize: { width: 1280, height: 720 } });
const slide = presentation.slides.add();
slide.background.fill = '#FFFFFF';
const C = { ink: '#333333', body: '#5E5E5E', coral: '#FF644E', accent: '#C84331', blue: '#3977A3', guide: '#D3D5D7' };

function textBox(name, text, x, y, w, h, size, color=C.ink, bold=false, align='left') {
  const s = slide.shapes.add({ name, geometry: 'textbox',
    position: { left:x*8, top:y*8, width:w*8, height:h*8 }, fill:'none', line:{fill:'none',width:0} });
  s.text=text;
  s.text.style={typeface:'Helvetica Neue',fontSize:size*2.822,bold,color,
    alignment:align,verticalAlignment:'middle',autoFit:'none',wrap:'none',insets:{left:0,right:0,top:0,bottom:0}};
  return s;
}
function circle(name,x,y,r,fill,stroke) {
  return slide.shapes.add({name,geometry:'ellipse',position:{left:(x-r)*8,top:(y-r)*8,width:r*16,height:r*16},
    fill,line:{fill:stroke??'none',width:stroke?1.7:0}});
}
function line(name,x1,y1,x2,y2,color,width=1.6) {
  // Horizontal or vertical lines only; preserve explicit positive geometry.
  return slide.shapes.add({name,geometry:'line',position:{left:Math.min(x1,x2)*8,top:Math.min(y1,y2)*8,
    width:Math.max(.01,Math.abs(x2-x1)*8),height:Math.max(.01,Math.abs(y2-y1)*8)},
    fill:'none',line:{fill:color,width}});
}
textBox('title','Can empty sellers drive a selloff?',9,5,142,10,20.5,C.ink,true);
textBox('premise','A trader can keep signaling Sell after its shares run out.',9,18,142,7,11);
textBox('original heading','Current model',13,28,62,6,10,C.accent,true,'center');
textBox('test heading','Proposed test',84,28,62,6,10,C.blue,true,'center');
for(const [cx,color,word] of [[44,C.coral,'Sell'],[115,C.blue,'Hold']]) {
  for(const [dx,dy] of [[0,-11],[-14,0],[14,0],[0,11]]) {
    line(`${word} link ${dx},${dy}`,cx,47,cx+dx,47+dy,color,1.5);
    circle(`${word} neighbor ${dx},${dy}`,cx+dx,47+dy,1.8,'#FFFFFF',C.guide);
  }
  circle(`${word} visible signal`,cx,47,6.3,color);
  textBox(`${word} label`,word,cx-6.2,43.8,12.4,6.4,10,'#FFFFFF',true,'center');
}
line('comparison divider',79.5,35,79.5,60,C.guide,1);
textBox('original caption','Neighbors read Sell',15,60.8,58,5.4,9,C.body,false,'center');
textBox('test caption','Neighbors read Hold',86,60.8,58,5.4,9,C.body,false,'center');
textBox('method','Change only what neighbors see when a seller has no shares.',9,68,142,5.5,10);
textBox('outcomes','Compare selling cascades, completed trades, and price drawdowns.',9,73,142,5.5,10);
textBox('deliverables label','Deliverables',9,81,23,5,9.5,C.accent,true);
textBox('deliverables','Reproducible Julia code + a paper in arXiv format',32,81,119,5,9.5);
textBox('conceptual note','Conceptual signal diagram, not simulation results.',9,86.7,80,2.8,5.5,C.body);
textBox('affiliation','Cornell Engineering   M.Eng. project',99,86.7,52,2.8,5.5,C.body,false,'right');
slide.speakerNotes.textFrame.setText(await fs.readFile(path.join(workspaceDir,'pitch-slide/speaker-notes.md'),'utf8'));

const candidatePath=path.join(buildDir,'candidate.pptx');
await (await PresentationFile.exportPptx(presentation)).save(candidatePath);
const preview=await presentation.export({slide,format:'png',scale:1.25});
await fs.writeFile(path.join(buildDir,'powerpoint-preview.png'),new Uint8Array(await preview.arrayBuffer()));
const layout=await slide.export({format:'layout'});
await fs.writeFile(path.join(buildDir,'powerpoint-layout.json'),await layout.text());
const finalPath=path.resolve(process.argv[2] ?? path.join(workspaceDir,'output/pptx/inventory-pitch.pptx'));
await finalizePresentation({workspaceDir,candidatePath,finalPath,
  explicitTotalSlideCount:1,requiredNativeTableOwnerSlides:[],requiredNativeChartOwnerSlides:[],
  pythonExecutable:RUNTIME_PYTHON,
  integrityValidatorPath:path.join(PRESENTATION_SKILL_DIR,'container_tools/inspect_presentation_package_integrity.py'),
  layoutValidatorPath:path.join(PRESENTATION_SKILL_DIR,'container_tools/inspect_presentation_layout_geometry.py'),
  layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-heading-fit'],
  fontPolicy,verifyArtifactToolImport:true,
  receiptPath:path.join(buildDir,'powerpoint-validation.json')});
console.log(finalPath);
