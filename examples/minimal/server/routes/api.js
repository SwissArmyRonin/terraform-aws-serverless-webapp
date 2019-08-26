var express = require('express');
var router = express.Router();

router.get('/todos', (req, res, next) => {
	res.json([
		{
			userId: 1,
			id: 1,
			title: 'delectus aut autem',
			completed: false
		},
		{
			userId: 1,
			id: 2,
			title: 'quis ut nam facilis et officia qui',
			completed: true
		},
		{
			userId: 1,
			id: 3,
			title: 'fugiat veniam minus',
			completed: false
		}
	]);
});

router.get('/users', (req, res, next) => {
	res.json([
		{
			id: 1,
			name: 'Leanne Graham',
			username: 'Bret',
			email: 'Sincere@april.biz',
			address: {
				street: 'Kulas Light',
				suite: 'Apt. 556',
				city: 'Gwenborough',
				zipcode: '92998-3874',
				geo: {
					lat: '-37.3159',
					lng: '81.1496'
				}
			},
			phone: '1-770-736-8031 x56442',
			website: 'hildegard.org',
			company: {
				name: 'Romaguera-Crona',
				catchPhrase: 'Multi-layered client-server neural-net',
				bs: 'harness real-time e-markets'
			}
		}
	]);
});

module.exports = router;
