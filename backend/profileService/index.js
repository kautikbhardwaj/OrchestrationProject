const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config()
var cors = require('cors')


const app = express();
const port = process.env.PORT || 3002;

mongoose.connect(process.env.MONGO_URL)
  .then(() => console.log('Connected to MongoDB'))
  .catch((error) => console.error('MongoDB connection error:', error.message));

app.use(express.json());
app.use(cors())


app.get('/health', (req,res)=>{
    res.send({status: 'OK'})
})

app.get('/ready', (req,res)=>{
    if (mongoose.connection.readyState === 1) {
      return res.send({status: 'READY'})
    }
    return res.status(503).send({status: 'NOT_READY'})
})

const userSchema = mongoose.Schema({
    name: {
        type: String,
        required: true,
        minlength: 1,
        maxlength: 200
    },
    age: {
        type: Number,
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now()
    }
})
const User = mongoose.model('user', userSchema)

app.post('/addUser', async (req,res)=>{
    try {
        const { name, age } = req.body;
        if (!name || !age) {
          return res
            .status(400)
            .json({ error: "Both name and age are required." });
        }
        const newuser = new User({
          name,
          age,
        });
        const savedUser = await newuser.save();
        res.status(201).json({ msg: "User Added Successfully" });
      } catch (err) {
        console.error(err);
        res.status(500).json({ err: "Internal Server Error" });
      }
})

app.get('/fetchUser', async (req,res)=>{
    try {
        console.log(req.body);
        let user = await User.find({});
        console.log(user);
        if (user) {
          res.send(user);
        } else {
          res.send({ msg: "User doesn't exist" });
        }
      } catch (err) {
        console.error(err);
        res.status(500).send({ msg: "Something went wrong" });
      }
})

const server = app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

process.on('SIGTERM', async () => {
  await mongoose.connection.close();
  server.close(() => process.exit(0));
});
