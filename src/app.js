const express = require('express');
const cors = require('cors');
const jobRoutes = require('./routes/jobRoutes');
const pedidosRoutes = require('./routes/pedidosRoutes');
const librosRoutes = require('./routes/librosRoutes')
const carritoRoutes = require('./routes/carritoRoutes')

const app = express();

app.use(cors());
app.use(express.json());
app.use('/api/jobs', jobRoutes);
app.use('/api/sale', pedidosRoutes);
app.use('/api/books', librosRoutes);
app.use('/api/cart',carritoRoutes);

module.exports = app;
