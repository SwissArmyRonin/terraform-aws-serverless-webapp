var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {
	res.status(404).send('These are not the droids you are looking for.');
});

module.exports = router;
