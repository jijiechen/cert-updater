if (!process.env.THIS_PUSH || process.argv.length < 4){ 
    console.log("incorrect number of arguments or missing environment variable.");
    process.exit(1);
 }

const cert_id = process.argv[2];
const state_file = process.argv[3];
const push_state = JSON.parse(process.env.THIS_PUSH);
const detect_only = !!process.env.DETECT_ONLY;
const fs = require("fs");

let existingState = { }
if(fs.existsSync(state_file)){
  existingState = JSON.parse( fs.readFileSync(state_file) )
}

 let alreadyPushed = false;
 if (existingState[cert_id]){
   existingState[cert_id].forEach(s => {
     let fieldMismatch = false;
     for(let f in push_state){
       if(!push_state.hasOwnProperty(f)){
         continue;
       }

       if(f === "_cert_dir"){
           continue;
       }

       if(!s.hasOwnProperty(f) || s[f] !== push_state[f]){
           fieldMismatch = true;
           break;
       }
     }

     if (!fieldMismatch){
       alreadyPushed = s;
       // break the forEach
       return false;
     }
   });
 }

 if (detect_only){
    console.log(alreadyPushed ? "" : "push=true");
    return;
 }

 if (alreadyPushed){
   console.log("cert " + cert_id + " had already been pushed on " + alreadyPushed._pushed_date  +". skipping this run.");
   return;
 }

 if (!existingState[cert_id]){
   existingState[cert_id] = [];
 }

 const now = new Date()
 push_state._pushed_date = `${now.getUTCFullYear()}-${now.getUTCMonth()+1}-${now.getUTCDate()} ${now.getUTCHours()}:${now.getUTCMinutes()}`;
 delete(push_state._cert_dir);
 existingState[cert_id].push( push_state );
 fs.writeFileSync(state_file, JSON.stringify(existingState));