#!/usr/bin/env node
/** KIN native control surface. See README.md for the source and QA contract. */
import { spawn } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync, mkdirSync, mkdtempSync, symlinkSync, rmSync, statSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';

const root = dirname(fileURLToPath(import.meta.url));
const project = join(root, 'godot');
const godot = process.env.GODOT ?? '/home/sandbox/Godot_v4.5.2-stable_linux.x86_64';
const [command, ...args] = process.argv.slice(2);
const opt = (name, fallback) => {
  const prefix = `--${name}=`;
  const value = args.find(a => a.startsWith(prefix));
  return value === undefined ? fallback : value.slice(prefix.length);
};
const bool = name => args.includes(`--${name}`);
const fail = (reason, details = {}) => { console.error(JSON.stringify({ ok: false, command, reason, ...details })); process.exitCode = 1; };
const pass = (details = {}) => console.log(JSON.stringify({ ok: true, command, ...details }));
const integer = (name, fallback, min, max) => {
  const raw = opt(name, String(fallback));
  const n = Number(raw);
  if (!Number.isInteger(n) || n < min || n > max) throw new RangeError(`${name} must be an integer in ${min}..${max}`);
  return n;
};
function launch(argv, timeoutMs) {
  return new Promise((done, reject) => {
    // Native OpenGL3 needs a display; xvfb-run is local, not a browser lease.
    const child = spawn('xvfb-run', ['-a', godot, '--audio-driver', 'Dummy', ...argv], { cwd: root, env: process.env });
    let out = '', err = '', timedOut = false;
    const timer = setTimeout(() => { timedOut = true; child.kill('SIGKILL'); }, timeoutMs);
    child.stdout.setEncoding('utf8'); child.stderr.setEncoding('utf8');
    child.stdout.on('data', chunk => { out += chunk; });
    child.stderr.on('data', chunk => { err += chunk; });
    child.on('error', reject);
    child.on('close', (code, signal) => { clearTimeout(timer); done({ code, signal, timedOut, out, err }); });
  });
}
function reportRun(result, extra) {
  const issues = (result.out + '\n' + result.err).split('\n').filter(line => /SCRIPT ERROR|ERROR:|Shader compilation failed|Parse Error/.test(line));
  if (result.timedOut || result.code !== 0 || issues.length) return fail('Godot failed', { ...extra, exitCode: result.code, signal: result.signal, timedOut: result.timedOut, issues, stderr: result.err.slice(-1200) });
  pass(extra);
}
if (!command || !['doctor', 'snapshot', 'screenshot', 'wait-settle', 'interact', 'ripple-queue', 'food-lifetime', 'zero-gap', 'ripple-bounds', 'fish-mesh'].includes(command)) {
  fail('Usage: control-kin.mjs doctor|snapshot|screenshot|wait-settle|interact|ripple-queue|food-lifetime|zero-gap|ripple-bounds|fish-mesh [--width=N --height=N --frames=N --out=path --dry-run]');
} else try {
  if (command === 'food-lifetime' || command === 'ripple-queue' || command === 'zero-gap' || command === 'ripple-bounds' || command === 'fish-mesh') {
    const argv = ['--headless', '--path', project, '--audio-driver', 'Dummy', '--script', `res://tools/${command === 'food-lifetime' ? 'food_lifetime' : command === 'zero-gap' ? 'zero_gap' : command === 'ripple-bounds' ? 'ripple_bounds' : command === 'fish-mesh' ? 'fish_mesh' : 'ripple_queue'}_qa.gd`];
    if (bool('dry-run')) pass({ argv, dryRun: true });
    else {
      const result = await launch(argv, 30_000);
      const proof = command === 'fish-mesh' ? 'FISH_MESH_QA ryukin verts=15174 triangles=27744 procedural_parts=10 procedural_tri=8032 procedural_degenerate=0 primitive_caps=256' : command === 'ripple-bounds' ? 'RIPPLE_BOUNDS_QA rejected=16 valid=3 ordered=1 cpu_rejected=10 cpu_valid=1' : command === 'zero-gap' ? 'ZERO_GAP_QA finite=2 separated=0.900 hard=0.900' : command === 'food-lifetime' ? 'FOOD_LIFETIME_QA cap=6 before=6 after_boundary=3 reopened=4 final=0 queued=7' : 'RIPPLE_QUEUE_QA count=32 first=68 last=99 batches=4 delivered=32 remaining=0';
      if (!result.out.includes(proof) || (command === 'fish-mesh' && !result.out.includes('FISH_MESH_QA demekin verts=19594 triangles=36192 procedural_parts=10 procedural_tri=8032 procedural_degenerate=0 primitive_caps=512'))) fail('QA proof missing', { exitCode: result.code, stdout: result.out.slice(-1200), stderr: result.err.slice(-1200) });
      else reportRun(result, { proof });
    }
  } else if (command === 'doctor') {
    const required = ['project.godot', 'labs/pond_lab.gd', 'labs/water_lab/ripple_sim.gdshader', 'export_presets.cfg'];
    const files = required.map(name => ({ name, exists: existsSync(join(project, name)) }));
    if (!existsSync(godot) || files.some(item => !item.exists)) fail('Missing Godot binary or project files', { godot, files });
    else pass({ godot, files, exportNext: existsSync(join(project, 'export_next/index.pck')) });
  } else if (command === 'snapshot') {
    const fields = ['godot/labs/pond_lab.gd', 'godot/labs/fish_lab.gd', 'godot/labs/water_lab/water_lab.gd'];
    const code = fields.map(name => ({ name, bytes: statSync(join(root, name)).size }));
    const text = readFileSync(join(project, 'labs/pond_lab.gd'), 'utf8');
    const gap = Object.fromEntries([...text.matchAll(/^const (GAP_[A-Z]+) = ([0-9.]+)/gm)].map(m => [m[1], Number(m[2])]));
    if (Object.keys(gap).length !== 3 || code.some(f => f.bytes < 100)) fail('Snapshot missing required logic values', { code, gap });
    else pass({ code, gap, exportPckBytes: existsSync(join(project, 'export_next/index.pck')) ? statSync(join(project, 'export_next/index.pck')).size : null });
  } else {
    const width = integer('width', 390, 320, 2560), height = integer('height', 844, 320, 2560);
    const frames = integer('frames', command === 'interact' || command === 'wait-settle' ? 90 : 46, 2, 18000);
    const lab = opt('lab', 'pond');
    if (!['pond', 'fish', 'water'].includes(lab)) throw new RangeError('lab must be pond, fish or water');
    const out = resolve(opt('out', `/tmp/kin-${command}-${width}x${height}`));
    if (!out.startsWith('/tmp/') && !out.startsWith('/downloads/') && !out.startsWith(root + '/')) throw new RangeError('out must be under /tmp, /downloads or this repo');
    const movie = command === 'screenshot';
    const argv = ['--path', project, '--rendering-driver', 'opengl3', '--resolution', `${width}x${height}`];
    if (movie) argv.push('--write-movie', join(out, 'f.png'), '--fixed-fps', '30');
    argv.push('--quit-after', String(frames), '--', `--lab=${lab}`, '--adapt=0');
    if (command === 'interact') argv.push('--autotap=1', '--gapqa=1');
    if (command === 'wait-settle') argv.push('--gapqa=1');
    if (bool('dry-run')) pass({ argv, out, dryRun: true });
    else {
      if (!existsSync(godot)) throw new Error(`Godot missing: ${godot}`);
      const frame = join(out, `f${String(frames - 6).padStart(8, '0')}.png`);
      // Never accept an old frame from a prior run as proof of a new render.
      if (movie && existsSync(frame)) throw new Error(`Screenshot target already exists: ${frame}; choose a new --out directory`);
      if (movie) mkdirSync(out, { recursive: true });
      // --write-movie ignores --resolution. Make a private project root rather
      // than editing tracked project.godot; SIGKILL cannot strand an override.
      const projectCfg = join(project, 'project.godot');
      const original = readFileSync(projectCfg, 'utf8');
      const changed = original.replace(/viewport_width=\d+/, `viewport_width=${width}`).replace(/viewport_height=\d+/, `viewport_height=${height}`);
      if (changed === original && (width !== 390 || height !== 844)) throw new Error('Project viewport keys not found');
      const isolated = mkdtempSync(join(tmpdir(), 'kin-control-'));
      let result;
      try {
        for (const entry of ['main.tscn', 'root.gd', 'main.gd', 'bowl.gd', 'koi.gd', 'goldfish.gd', 'fish_draw.gd', 'shaders', 'labs', 'icon.svg']) {
          if (!existsSync(join(project, entry))) throw new Error(`Isolated project missing ${entry}`);
          symlinkSync(join(project, entry), join(isolated, entry));
        }
        writeFileSync(join(isolated, 'project.godot'), changed);
        argv[1] = isolated;
        result = await launch(argv, Math.max(90_000, Math.ceil(frames * 450)));
      } finally {
        rmSync(isolated, { recursive: true, force: true });
      }
      const samples = [...result.out.matchAll(/^GAP t=([0-9.]+) min=([0-9.]+)/gm)].map(m => ({ time: Number(m[1]), min: Number(m[2]) }));
      const eats = [...result.out.matchAll(/^ATE t=([0-9.]+) by (\w+)/gm)].map(m => ({ time: Number(m[1]), fish: m[2] }));
      const runIssues = (result.out + '\n' + result.err).split('\n').filter(line => /SCRIPT ERROR|ERROR:|Shader compilation failed|Parse Error/.test(line));
      if (result.code !== 0 || result.timedOut || runIssues.length) reportRun(result, { argv, out });
      else if (command === 'interact' && (samples.length < 2 || eats.length !== 2 || new Set(eats.map(e => e.fish)).size !== 2 || samples.some(s => !Number.isFinite(s.min) || s.min < 0.72))) fail('Non-vacuous interaction assertion failed', { argv, out, gapSamples: samples.length, eats, lastLog: result.out.slice(-1800) });
      else if (command === 'wait-settle' && (samples.length < 2 || samples.some(s => !Number.isFinite(s.min) || s.min < 0.72))) fail('No valid gap samples', { argv, out, gapSamples: samples.length, lastLog: result.out.slice(-1800) });
      else {
        if (movie && (!existsSync(frame) || statSync(frame).size < 10_000)) fail('Missing or empty screenshot frame', { frame, argv });
        else if (movie && (() => { const h = readFileSync(frame).subarray(0, 24); return h.toString('hex', 0, 8) !== '89504e470d0a1a0a' || h.readUInt32BE(16) !== width || h.readUInt32BE(20) !== height; })()) fail('Screenshot dimensions mismatch', { frame, expected: [width, height] });
        else reportRun(result, { argv, out, frame: movie ? frame : null, gapSamples: samples.length, minGap: samples.length ? Math.min(...samples.map(s => s.min)) : null, eats });
      }
    }
  }
} catch (error) {
  if (error instanceof RangeError || error instanceof TypeError || error?.code === 'ENOENT' || error?.code === 'EEXIST' || (error instanceof Error && error.message.startsWith('Screenshot target already exists:'))) fail(error.message);
  else throw error;
}
