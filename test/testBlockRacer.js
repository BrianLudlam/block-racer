const truffleAssert = require('truffle-assertions');
const BlockRacer = artifacts.require("BlockRacer");
const Entity = artifacts.require("./ERC721Entity/ERC721Entity");

const SPAWNING_FEE = "4000000000000000";//4 finney

const L0_RACE_COST = "22000000000000000";//22 finney
const L1_RACE_COST = "23800000000000000";//23.8 finney
const L2_RACE_COST = "25600000000000000";//25.6 finney

const logThis = (obj) => console.log('LOG - ',obj);

const processLaneDistance = (_lane, _racer, _raceDistance, _raceHashs) => {
	let racerBlockhash;
	let speed = parseInt(_racer.speed,10);
	let max = parseInt(_racer.max,10);
	let distance = 0;
	let split;
	let splits;
	let block=0;
	while (block < 12 && distance < _raceDistance) {
		racerBlockhash = web3.utils.soliditySha3 (_racer.seed, _raceHashs[block]);
		splits = 0;
		while (splits < 32 && distance < _raceDistance) {
			split = parseInt("0x"+racerBlockhash.substring( 2+(splits*2), 4+(splits*2) ), 16);
			distance += ((speed + split < max) ? speed + split : max);
			if (distance < _raceDistance) splits++;
		}
		if (distance < _raceDistance) block++;
	}
	return {
		id: _racer.id.toString(), 
		lane: _lane, 
		distance, 
		split: (block * 32) + splits
	};
};

const finishSort = (a, b) => (
  //yield to lowest final split
  (a.split > b.split) ? 1 :
  (a.split < b.split) ? -1 : 
  //final split the same, yield to hishest final speed
  (a.distance < b.distance) ? 1 : 
  (a.distance > b.distance) ? -1 : 
  //final split and speed the same, yield to inside lane
  (a.lane < b.lane) ? -1 : 1
);



contract("BlockRacer", (accounts) => {

	const operator = accounts[0];
	const alice = accounts[1];
	const bob = accounts[2];

  let racingEntity;
  let racetrack;
  // build up and tear down a new Casino contract before each test
  beforeEach(async () => {
    racingEntity = await Entity.new({from: operator});
    racetrack = await BlockRacer.new(racingEntity.address, {from: operator});
  });
  
  afterEach(async () => {
    await racetrack.destroy({from: operator});
    await racingEntity.destroy({from: operator});
  });

  it("should act like a BlockRacer.", async () => {
  	let tx;
  	let block = await web3.eth.getBlock("latest");
  	let blockNumber = block.number;
  	for (let i=1; i<=6; i++) {
  		tx = await racingEntity.createEntity ("", 0, 0, {from: alice, value: SPAWNING_FEE});
  		assert.equal (tx.receipt.status, true, "createEntity");
  	}
  	for (let i=1; i<=6; i++) {
  		tx = await racingEntity.createEntity ("", 0, 0, {from: bob, value: SPAWNING_FEE});
  		assert.equal (tx.receipt.status, true, "createEntity");
  	}
  	for (let i=1; i<=12; i++) {
  		tx = await racingEntity.spawnEntity ({from: operator});
  		assert.equal (tx.receipt.status, true, "spawnEntity");
  	}
  	let racers = [];
  	let racer;
  	let genes;
  	for (let i=1; i<=12; i++) {
  		racer = i.toString();
  		genes = await racingEntity.genesOf (racer, {from: operator});
  		assert.equal (genes.reduce((total, num) => (total + num)) > 0, true, "Has genes");
  		racers.push(racer);
  	}
  	//logThis(racers);

  	let _qLength = await racetrack.getRaceQueue (0, {from: operator});
		assert.equal (_qLength, 0, "Queue ready.");
		let owner;
		for (let i=1; i<=6; i++) {
  		racer = i.toString();
  		tx = await racetrack.enterRaceQueue (racer, {from: alice, value: L0_RACE_COST});
  		truffleAssert.eventEmitted(tx, 'RaceEntered', (e) => (
	  		e.owner.toString() === alice && 
	    	e.racer.toString() === racer && 
	    	e.race.toString() === "1" &&
	    	e.lane.toString() === racer
	  	));
	  	if (i === 6) {
				truffleAssert.eventEmitted(tx, 'RaceStarted', (e) => (
		  		e.race.toString() === "1" && 
		    	e.distance.toString() === "120000" && 
		    	e.conditions > 0
		  	));
		  	_qLength = await racetrack.getRaceQueue (0, {from: operator});
				assert.equal (_qLength, 0, "Queue reset.");
			} else {
				_qLength = await racetrack.getRaceQueue (0, {from: operator});
				assert.equal (_qLength, i, "Queue working.");
			}
  	}

  	for (let i=1; i<=5; i++) {
  		racer = (i+6).toString();
  		tx = await racetrack.enterRaceQueue (racer, {from: bob, value: L0_RACE_COST});
  		truffleAssert.eventEmitted(tx, 'RaceEntered', (e) => (
	  		e.owner === bob && 
	    	e.racer.toString() === racer && 
	    	e.race.toString() === "2" &&
	    	e.lane.toString() === i.toString()
	  	));
  	}

  	tx = await racetrack.exitRaceQueue ("11", {from: bob});
		truffleAssert.eventEmitted(tx, 'RaceExited', (e) => (
  		e.owner === bob && 
    	e.racer.toString() === "11" && 
    	e.race.toString() === "2" &&
    	e.lane.toString() === "5"
  	));

  	tx = await racetrack.enterRaceQueue ("12", {from: bob, value: L0_RACE_COST});
		truffleAssert.eventEmitted(tx, 'RaceEntered', (e) => (
  		e.owner === bob && 
    	e.racer.toString() === "12" && 
    	e.race.toString() === "2" &&
    	e.lane.toString() === "5"
  	));

  	for (let i=1; i<=4; i++) {
  		racer = (i+6).toString();
  		tx = await racetrack.exitRaceQueue (racer, {from: bob});
  		truffleAssert.eventEmitted(tx, 'RaceExited', (e) => (
	  		e.owner === bob && 
	    	e.racer.toString() === racer && 
	    	e.race.toString() === "2"
	  	));
  	}

  	tx = await racetrack.exitRaceQueue ("12", {from: bob});
		truffleAssert.eventEmitted(tx, 'RaceExited', (e) => (
  		e.owner === bob && 
    	e.racer.toString() === "12" && 
    	e.race.toString() === "2" &&
    	e.lane.toString() === "1"
  	));

  	_qLength = await racetrack.getRaceQueue (0, {from: operator});
		assert.equal (_qLength, 0, "Queue working.");

		block = await web3.eth.getBlock("latest");
		let race = await racetrack.getRace ("1", {from: operator});
		assert.equal (block.number.toString(), race.start.toString(), "block check");

		let raceHashs = [block.hash];
		for (let i=1; i<=12; i++) {
  		tx = await racingEntity.nameEntity ("1", "Alice1", {from: alice});
  		assert.equal (tx.receipt.status, true, "nameEntity");
  		block = await web3.eth.getBlock("latest");
  		raceHashs.push(block.hash);
  	}

  	let raceResult = [];
  	let raceLane;
  	for (let lane=1; lane<=6; lane++) {
  		raceLane = await racetrack.getRaceLane ("1", lane, {from: operator});
  		raceResult.push(
  			processLaneDistance(lane, raceLane, parseInt(race.distance, 10), raceHashs)
  		) 
  	}
  	raceResult.sort(finishSort);

		//11 blocks have passed since start block, next block is first settle block

		let numSettling = await racetrack.numSettling ({from: operator});
		assert.equal (numSettling, 0, "Settle working.");

  	for (let i=1; i<=6; i++) {
  		tx = await racetrack.settleRace ("1", {from: operator});
  		assert.equal (tx.receipt.status, true, "settleRace");
  		truffleAssert.eventEmitted(tx, 'LaneSettled', (e) => (
	  		e.race.toString() === "1" &&
	    	e.settler.toString() === operator && 
	    	e.lane.toString() === i.toString()
	  	));
  	}

  	numSettling = await racetrack.numSettling ({from: operator});
		assert.equal (numSettling, 1, "Settle working.");

  	tx = await racetrack.settleRace ("1", {from: operator});
		assert.equal (tx.receipt.status, true, "settleRace");
		truffleAssert.eventEmitted(tx, 'RaceSettled', (e) => (
  		e.race.toString() === "1" &&
    	e.settler.toString() === operator
  	));

  	numSettling = await racetrack.numSettling ({from: operator});
		assert.equal (numSettling, 0, "Settle working.");

		race = await racetrack.getRace ("1", {from: operator});

  	for (let i=0; i<6; i++) {
  		assert.equal (race.finish[i].toString(), raceResult[i].lane.toString(), "Result verified.");
  	}

  	//logThis(race.finish);
  	//logThis(raceResult);

		//assert.equal (1, 0, "Fail for events.");

  });

});