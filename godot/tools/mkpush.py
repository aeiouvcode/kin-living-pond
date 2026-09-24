import subprocess, json, base64, sys
c, expected = sys.argv[1], sys.argv[2]
msg=subprocess.check_output(['git','log','-1','--format=%B',c]).decode().strip()
files=subprocess.check_output(['git','diff-tree','--no-commit-id','-r','--name-only',c]).decode().split()
C=[{'msg':msg,'local':c,'files':[{'path':p,'b64':base64.b64encode(subprocess.check_output(['git','show',f'{c}:{p}'])).decode()} for p in files]}]
js = r"""
const C=JSON.parse(document.getElementById('d').textContent);
go.onclick=async()=>{const o=document.getElementById('o');const log=s=>o.textContent+='\n'+s;
try{const R='https://api.github.com/repos/aeiouvcode/kin-living-pond';const h={Accept:'application/vnd.github+json',Authorization:'Bearer '+t.value,'X-GitHub-Api-Version':'2022-11-28','Content-Type':'application/json'};
const j=async(u,m,b)=>{const r=await fetch(R+u,{method:m||'GET',headers:h,body:b?JSON.stringify(b):undefined});const d=await r.json().catch(()=>({}));if(!r.ok)throw new Error((m||'GET')+' '+u+' '+r.status+' '+(d.message||''));return d;};
const ref=await j('/git/ref/heads/godot-prototype');let parent=ref.object.sha;log('branch '+parent);
if(parent!=='EXPECTED')throw new Error('branch moved, re-read first');
for(const c of C){const pc=await j('/git/commits/'+parent);const tree=[];
for(const f of c.files){const b=await j('/git/blobs','POST',{content:f.b64,encoding:'base64'});tree.push({path:f.path,mode:'100644',type:'blob',sha:b.sha});}
const tr=await j('/git/trees','POST',{base_tree:pc.tree.sha,tree});
const cm=await j('/git/commits','POST',{message:c.msg,tree:tr.sha,parents:[parent]});parent=cm.sha;log(c.local+' -> '+cm.sha+' tree '+tr.sha);}
await j('/git/refs/heads/godot-prototype','PATCH',{sha:parent,force:false});t.value='';log('DONE '+parent);}catch(e){t.value='';log('ERR '+e.message);}};
""".replace('EXPECTED', expected)
h = '<!doctype html><meta charset=utf-8><script type=application/json id=d>'+json.dumps(C).replace('</','<\\/')+'</script><label>token <input id=t type=password></label><button id=go>Push</button><pre id=o>ready</pre><script>'+js+'</script>'
open('/tmp/push.js','w').write('document.open();document.write('+json.dumps(h)+');document.close();return document.getElementById("d")?"ok":"no"')
print(len(files),'files')
