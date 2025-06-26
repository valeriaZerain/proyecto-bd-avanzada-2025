const express = require('express');
const router = express.Router();
const { runBackup } = require('../jobs/backupJob');

router.post('/backup', (req, res) => {
    runBackup();
    res.json({ message: 'Backup ejecutado manualmente.' });
});

module.exports = router;
