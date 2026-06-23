const fs=require('fs');
const code=fs.readFileSync('C:/Users/blain/OneDrive/Documents/Claude/Projects/Generals_Clone/generals-zero-hour.html','utf8').match(/<script>([\s\S]*)<\/script>/)[1];
try{ new Function(code); }catch(e){ console.log('SYNTAX ERROR: '+e.message); process.exit(2); }
const gone = code.includes('drawBldDamage(c,b,px,py,w)');  // the CALL should be gone (def may remain)
const box = code.includes("if(!(b.done && (bs || b.def.wall)))");
console.log('SYNTAX OK; box-conditional='+box+'; damage-overlay-call-still-present='+gone);
