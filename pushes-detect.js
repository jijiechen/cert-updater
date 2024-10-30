const fs = require("fs");
const path = require("path");

if (process.argv.length < 3){ 
    console.error("incorrect number of arguments.");
    process.exit(1);
}

const configFile = process.argv[2];

if(!fs.existsSync(configFile)){
  console.error("File does not exist: " + configFile);
  process.exit(1);
}

const config = JSON.parse(fs.readFileSync(configFile));
if (!config.certificates || !config.certificates.length){
  return;
}

const isStaging = config.acme?.staging;
let certDir = "certs";
if (isStaging){
  certDir = "staging-certs"
}

const pushes = {};
config.certificates.filter(c => c.pushes && c.pushes.length > 0).forEach(cert =>{
  cert.pushes.forEach(p =>{
    for(var k in p){
      if(p.hasOwnProperty(k)){
        if(!pushes[k]){
          pushes[k] = [];
        }

        const certInfo = p[k];
        certInfo._cert_dir = path.join(certDir, cert.domains[0]);
        pushes[k].push(certInfo);
      }
    }
  });
});

console.log("matrix=" + JSON.stringify(pushes));
