import KJUR from 'jsrsasign'
const header = { alg: 'HS256', typ: 'JWT' }
const secret = process.argv[2];
const payload = JSON.parse(process.argv[3]);
const jwtkey = KJUR.jws.JWS.sign(null, header, payload, secret)
console.log(jwtkey)