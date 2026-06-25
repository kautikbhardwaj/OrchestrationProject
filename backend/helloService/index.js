const express = require('express');
require('dotenv').config()
var cors = require('cors')

const app = express();
const port = process.env.PORT || 3001;
app.use(cors())
app.use(express.json());

app.get('/', (req,res)=>{
    res.send({msg: 'Hello World'})
})

app.get('/health', (req,res)=>{
    res.send({status: 'OK'})
})

const server = app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

process.on('SIGTERM', () => server.close(() => process.exit(0)));
