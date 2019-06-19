pragma solidity ^0.5.8;
import "./IEntity.sol";
import "./IBlockRacer.sol";

/**
 * @title BlockRacer Contract
 * @author Brian Ludlam
 * 
 * BlockRacer Contract
 * 
 * BlockRacer is a game allowing players (per Eth account) to compete against each
 * other, by racing ERC721Entity tokens around a blockchain-mechanics-driven racetrack. 
 * Players win Eth by winning races, and potentially earn Eth by contributing to 
 * the settlement of race results. Racing performance is part skill in training, 
 * and part randomness determined by block hash creation over time. Racers increase 
 * level as they are trained, and are able to enter higher level races at higher levels. 
 * Higher level races cost more to enter and payout more to winners. Lower level races are
 * more determined by randomness than training skill, and higher level races are more 
 * determined by training skill than randomness.
 * 
 * Racers
 * 
 * Racers are non-fungible token entities, following IERC721Entity, which follows IERC721 
 * and in turn IERC21. The two IERC721Entity functions interfaced are: ownerOf - returning 
 * the address of the racer's owner, and genesOf - returning an immutable array of 32 8bit 
 * genes determining the racer's training potential. Racers can: Race and Train. Training 
 * increases racer performance and racer level in following races. Racing increases player 
 * experience points. Player experience points are used to train racers.
 * 
 * Player Experience 
 * 
 * Player experience points are collected per account, by racing racers in races. Player 
 * experience is used to train account owned racers. For each racer in each race finished 
 * (regardless of placing), the racer's owner collects 1-3 experience points; 1 point most 
 * commonly, 2 at about 1:5 chance, and 3 about 1:50.
 * 
 * Training and Levels
 * 
 * Training costs player experience points. Training involves increasing 3 main racer 
 * stats: acceleration, top speed, and traction. Racer level is always total training 
 * points / 8 (rounded down), so training automatically increases level. Training a 
 * racer has no fee, and only requires ~70k gas. The maximum training a racer can have 
 * is determined by racer's genes, specially the first 3 genes, used as: acceleration, 
 * top speed, and traction potentials. Max training potential for each stat is 255.
 * (8bit genes) Max training and max level are different for each racer, based on 
 * potential (genes), with overall max being 255 (rare) in all 3 stats, giving max 
 * level of 3 * 255 / 8 = 95 (extremely rare.)
 * 
 * Race Queue
 * 
 * Racer entity enters race queue, by id, at it's current level. Race queue is 6 
 * deep for each level. A race starts once 6 racers (lanes), at the same level, 
 * are queued. Racer performance values are set permanently upon entering race. 
 * Any training during race will not effect performance, or race level change, 
 * until next race. Racer can only be in one race at a time. Racers may exit race 
 * queue before race starts, but not after.
 * 
 * Race Cost / Fees
 * 
 * Race Entry Cost = Racing Fee + Settlement Fee
 * 
 * 100% of player fees collected are transferred to player contributors in the system.
 * 
 * The system has two fees: Settlement Fee and Racing Fee; both are collected upon 
 * entering the race queue. Both are refunded upon exiting race queue. Settlement 
 * fee is always the same at 4 finney per racer per race, consistently payed out as 
 * rewards to those who settle each race. Racing fee is scaled by level, starting at 
 * 18 finney, increasing by 1.8 finney per level. Racing fees from each race are 
 * payed out as a reward to those who win/place that race: first, second, and third. 
 * After a race completes, all fees are payed out. Neither the contract, or the 
 * contract owner, retain any fees.
 * 
 * Race Process
 * 
 * A race begins once 6 racers of the same level are queued. The start of a race is 
 * signified by setting the race's start block to the next block number from the 
 * block which processed the block start / the 6th racer being queued at a specific 
 * level. Each racer has performance variables set upon entry, and a performance 
 * seed, which combined with each block hash starting with the start block, will 
 * give a distance travelled during that block. Each race has a set level-based 
 * distance to the finish line. Each block following start block provides a block 
 * hash, translating into unique racer distance travelled during that block. This 
 * distance can be calculated in parallel to the system (by a UI) to show race 
 * progress and result, without any transactions needed to keep the race going. 
 * Once started, the race goes until all racers reach the finish line. In order 
 * to "settle" the race - payout both player experience and winner rewards to all 
 * racer owners, as well as claim settlement rewards - players can run the 
 * settleRace function.
 * 
 * Race Settlement 
 * 
 * Race Settlement is required to settle each race. Anyone can contribute to, 
 * and profit from, the settling of any race. Each race requires 7 settlement 
 * transactions: 1 for each of 6 lanes, and one more to finalize the race result 
 * and payout winners. The gas needed to finalize a race is the highest at ~350k 
 * so pays the most, 5 finney. The first settler is the next most expensive at 
 * ~250k, so pays out 4 finney. The middle settlers (lanes 2-6) are all about 
 * ~200k, each payout 3 finney. Settlement order is first come first served per 
 * race, and settlement transactions without a race to settle will fail, costing 
 * ~1/5 finney. The reward for settling a race is ~15-20 times the cost of a 
 * failed settlement, so relatively efficient for high competition and scheduled 
 * automation. Trying to settle a race before it finishes (all racers reach 
 * finish-line/ race distance) will also fail. Before allowing failed settlement, 
 * the system will first try to provide race settlers with any other possible 
 * race to settle before failing, to reduce failures. Note, the system is not 
 * aware of a race being ready to settle until the first settlement transaction 
 * occurs. The system does not know about any race result, until informed through 
 * settlement transactions. After the first settlement transaction is received for 
 * a race, the system is able to reroute other settlers to that race, upon potential 
 * fail in settling their intended race. For example, if 8 transactions to settle the 
 * same race occur all at the same time on one block. The first 7 will be successful 
 * and the 8th will potentially fail. However, if there is another race available to 
 * settle, the 8th settler will be rerouted to settle that other race instead, etc. 
 * A failure only potentially occurs if there are no races to settle; all races being 
 * either already settled or not finished yet.
 * 
 * Race Expiration
 * 
 * Given the block history limit of 256 blocks in Ethereum, after 256 blocks a race - 
 * whether settled or not - becomes expired, and can no longer be settled or 
 * "replayed". When a race becomes expired before being fully settled, the following 
 * settlement that comes in, will refund all racers' Racing Fees, and settler will 
 * collect all 24 finney of the race's settlement rewards. This encourages racers to 
 * take responsibility of settling own races, as well as max reward for settlers of 
 * expired races, in order prevent any backlog of expired races (and refunding of fees 
 * collected). When a race becomes expired after being settled, it can no longer be 
 * replayed by a UI, due to the Eth block history limit, however if a history preserved 
 * (within UI, Oracle, or other contract) a block hash history going back further than 
 * 256 blocks would allow potentially any race to always be replayable by UI. However, 
 * expired races that are not settled can never be settled internally by the system 
 * with accurate results, due to Eth history limit, hence refund.
 * 
 * Track Conditions
 * 
 * Each race starts with specific track conditions (wet vs dry) according to an 
 * accumulative random weather pattern shifting between 1 (most dry) and 255 
 * (most wet/muddy.) Each race has a random chance to increment or decrement by 
 * 1-3, or remain the same. Racer's traction training alleviates track condition 
 * speed penalty.
 * 
 */
contract BlockRacer is IBlockRacer {

    uint256 constant SETTLER_FEE = 4000000000000000;//4 finney * 6 = 24 finney per race
    uint256 constant FIRST_SETTLER_REWARD = 4000000000000000;//4 finney per race
    uint256 constant SETTLER_REWARD = 3000000000000000;//3 finney * 5 = 15 finney per race
    uint256 constant LAST_SETTLER_REWARD = 5000000000000000;//5 finney per race
    uint256 constant COST_BASE = 18000000000000000;//18 finney 
    uint256 constant COST_MULT = 1800000000000000;//1.8 finney 
    uint256 constant FIRST_BASE = 48000000000000000;//48 finney 
    uint256 constant FIRST_MULT = 4800000000000000;//4.8 finney 
    uint256 constant SECOND_BASE = 36000000000000000;//36 finney 
    uint256 constant SECOND_MULT = 3600000000000000;//3.6 finney 
    uint256 constant THIRD_BASE = 24000000000000000;//24 finney 
    uint256 constant THIRD_MULT = 2400000000000000;//2.4 finney 
    
    uint8 constant VERIFY_BLOCKS = 12;
    uint8 constant LANE_COUNT = 6;
    uint16 constant SPEED_BASE = 128;
    uint16 constant SPEED_MULT = 5;
    uint16 constant MAX_DIFF = 128;
    uint16 constant FRICTION_BASE = 512; 
    uint8 constant SPLITS_PER_BLOCK = 32;
    uint8 constant LEVEL_DISTANCE_GAIN = 8;
    uint8 constant AVG_RACE_SPLITS = 200;// ~6 laps, ~= 1:45 min:sec if cofig'd right
    uint32 constant DISTANCE_BASE = 120000;

    struct Race {
        uint start;
        uint16 level;
        uint32 distance;
        uint8 conditions;
        bool settled;
    }

    struct Lane {
        uint256 id;
        bytes32 seed;
        uint16 speed;
        uint16 max;
        uint32 distance;
        uint16 split;
        uint8 exp;
        bool settled;
    }
    
    //contract developer, power to destroy/upgrade
    address payable private _developer;
    
    IEntity _entity;
    mapping(address => uint32) _accountExp;
    uint256 _raceNumber;
    mapping(uint256 => Race) _race;
    mapping(uint16 => uint256) _raceQueue;
    mapping(uint256 => mapping(uint8 => Lane)) _raceLane;
    mapping(uint256 => uint8) _lanesReady;
    mapping(uint256 => uint8) _lanesSettled;
    mapping(uint256 => uint8[]) _lanesFinish;
    mapping(uint256 => uint256) _settleQueue;
    uint _firstSettling;
    uint _lastSettling;
    mapping(uint256 => uint256) _racerLastRace;
    mapping(uint256 => uint8) _racerAcceleration;
    mapping(uint256 => uint8) _racerTopSpeed;
    mapping(uint256 => uint8) _racerTraction;
    
    //@param entityAddress - address of ERC721Entity contract required to construct.
    constructor(address entityAddress) public { 
        _developer = msg.sender;
        _entity = IEntity (entityAddress);
        //init settle queue
        _firstSettling = 1;
        //init track conditions, and first race write
        _race[0] = Race (0, 0, 0, 128, true);
    }
    
    function enterRaceQueue (uint256 id) external payable {
        //sender must be racer's (token entity's) owner
        address owner = _entity.ownerOf(id);
        require (owner == msg.sender, 'Not your Racer.');
        //racer can only enter one race at a time.
        require (_racerLastRace[id] == 0 || _race[_racerLastRace[id]].settled, 
            'Racer already racing.');
        
        //Racer level = total training points / 8, rounded down.
        uint16 level = racerLevel (
            _racerAcceleration[id], 
            _racerTopSpeed[id], 
            _racerTraction[id]
        );
        //Racing fee = 18 finney + (Racer Level * 1.8 finney)
        //Settlement Fee = 4 finney.
        //Race Cost = Racing fee + Settlement Fee.
        uint256 raceCost = raceCost (level);
        require (msg.value >= raceCost, "Cost not covered.");
    
        //if race queue at racer's level is empty, create the race first.
        if (_raceQueue[level] == 0) {
            _raceQueue[level] = ++_raceNumber;
            _race[_raceNumber] = Race (
                0,
                level,
                raceDistance(level),
                nextTrackConditions(
                    _race[_raceNumber-1].conditions, 
                    (uint8 (uint (blockhash(block.number)) % 256))
                ),
                false
            );
        }
        
        //Set race to current race queue at racer's level, also mutex.
        uint256 raceNumber = _racerLastRace[id] = _raceQueue[level];
    
        //Snapshot of racer training and track conditions to baseline race performance
        (
        uint16 speed,
        uint16 max
        ) = initRacer(
            _racerAcceleration[id], 
            _racerTopSpeed[id],
            _racerTraction[id],
            _race[raceNumber].conditions
        );
        
        //Each racer gets a unique seed to hash with race blockhashs
        bytes32 seed = keccak256 (abi.encodePacked (
            owner, 
            id, 
            blockhash(block.number)
        ));
        
        //Add racer to net available lane in race queue
        uint8 lane = ++_lanesReady[raceNumber];
        _raceLane[raceNumber][lane] = Lane(
            id,
            seed,
            speed,
            max,
            0,0,0,false
        );
    
        //watch for start event (once) after entering a race queue
        emit RaceEntered (
            owner, 
            id, 
            raceNumber, 
            lane, 
            now
        );
        
        //If queue filled/ready, start race on next block, and reset queue.
        if (_lanesReady[raceNumber] == LANE_COUNT) {
            _race[raceNumber].start = block.number + VERIFY_BLOCKS;
            _raceQueue[level] = 0;//reset queue
            emit RaceStarted (
                raceNumber, 
                _race[raceNumber].distance, 
                _race[raceNumber].conditions,
                now
            );
        }
        
        //return any change
        if (msg.value > raceCost) 
            msg.sender.transfer(msg.value - raceCost);
    }

    function exitRaceQueue (uint256 id) external {
        //sender must be racer's (token entity's) owner
        address owner = _entity.ownerOf(id);
        require (owner == msg.sender, 'Not your entity.');
        
        //racer must currently be racing, and race not yet started.
        require (_racerLastRace[id] != 0, 'Racer not racing.');
        require (_race[_racerLastRace[id]].start == 0, 'Race already started.');
        
        //clear racer's last race, also mutex.
        uint256 raceNumber = _racerLastRace[id];
        _racerLastRace[id] = 0;
        
        //Find racer in race queue, remove racer, and refund owner
        bool found = false;
        uint8 lane = 1;
        while (!found && lane <= LANE_COUNT) {
            if (_raceLane[raceNumber][lane].id == id)
                found = true;
            else lane++;
        }
        if (found) {
            if (lane < _lanesReady[raceNumber])
                _raceLane[raceNumber][lane] = _raceLane[raceNumber][_lanesReady[raceNumber]];
            delete _raceLane[raceNumber][_lanesReady[raceNumber]--];
            uint256 refund = raceCost (_race[raceNumber].level);
            msg.sender.transfer(refund);
            emit RaceExited(
                owner, 
                id, 
                raceNumber, 
                lane, 
                now
            );
        }
    }

    function settleRace (uint race) external {
        //if race not started, not verified or already settled, 
        //try settling next unsettled race via settleQueue
        uint256 raceNumber = (
            (_race[race].start == 0 || //lanes not ready, not started
            _race[race].start + VERIFY_BLOCKS > block.number || //not verified yet
            _race[race].settled) && //already settled
                _lastSettling >= _firstSettling //there are other races to settle
        ) ? _settleQueue[_firstSettling] : race;
            
        //Race must be started, verified, and not already settled.
        require (
            _race[raceNumber].start != 0 && 
            _race[raceNumber].start + VERIFY_BLOCKS <= block.number &&
            !_race[raceNumber].settled, 
            'No race to settle.'
        );
        
        //If race is expired, refund racer owners, if lanes to settle, settle lanes,
        //else settle (finalize) the race itself.
        if (block.number >= _race[raceNumber].start + 255)
            refundExpiredRace (raceNumber);
        else if (_lanesSettled[raceNumber] < LANE_COUNT) 
            settleNextLane (raceNumber);
        else settleFinish (raceNumber);
    }
    
    function train (uint256 id, uint8[] calldata training) external { 
        //sender must be racer's (token entity's) owner
        address owner = _entity.ownerOf(id);
        require (owner == msg.sender, 'Entity not yours.');
        
        //Training must be an array of 3 values, totaling less than 
        //or equal to account experience points left, and each totaling less than
        //or equal to recer's training potential, once combined with existing training.
        //If valid, update racer with new training, and reduce owner exp accordingly.
        require (training.length == 3, "training should be array size 3.");
        uint16 trainingTotal = training[0] + training[1] + training[2];
        require (trainingTotal > 0 && trainingTotal <= _accountExp[owner], 
            "Training experience mismatch.");
        uint8[] memory genes = _entity.genesOf(id);
        require (_racerAcceleration[id] + training[0] <= genes[0], 
                "Acceleration training over potential.");
        require (_racerTopSpeed[id] + training[1] <= genes[1], 
                "Top speed training over potential.");
        require (_racerTraction[id] + training[2] <= genes[2], 
                "Traction training over potential.");
                
        //reduce player account experience
        _accountExp[owner] -= trainingTotal;//accumlative mutex
        
        //add training to racer
        if (training[0] > 0)
            _racerAcceleration[id] += training[0];
        if (training[1] > 0)
            _racerTopSpeed[id] += training[1];
        if (training[2] > 0)
            _racerTraction[id] += training[2];
            
        emit RacerTrained (
            owner, 
            id, 
            training[0],
            training[1],
            training[2],
            now
        );
    }

    /* Testing only - remove from production or add proxy update-able interface */
    function destroy() external {
       require (_developer == msg.sender);
       selfdestruct(_developer);
    }
    
    /* Return to sender any abstract transfers */
    function () external payable { msg.sender.transfer(msg.value); }
    
    function getRace (uint raceNumber) external view returns (
        uint start,
        uint16 level,
        uint32 distance,
        uint8 conditions,
        uint8 lanesReady,
        uint8 lanesSettled,
        bool settled,
        uint256[] memory racers,
        uint8[] memory finish
    ) { 
        start = _race[raceNumber].start;
        level = _race[raceNumber].level;
        distance = _race[raceNumber].distance;
        conditions = _race[raceNumber].conditions;
        lanesReady = _lanesReady[raceNumber];
        lanesSettled = _lanesSettled[raceNumber];
        settled = _race[raceNumber].settled;
        finish = _lanesFinish[raceNumber];
        racers = new uint256[](LANE_COUNT);
        if (_lanesReady[raceNumber] > 0) {
            for (uint8 lane=1; lane<=LANE_COUNT; lane++) {
                racers[lane-1] = _raceLane[raceNumber][lane].id;
            }
        }
    }

    function getRaceLane (uint raceNumber, uint8 lane) external view 
        returns (uint256 id, bytes32 seed, uint16 speed, uint16 max, bool settled){
        
        id = _raceLane[raceNumber][lane].id;
        seed = _raceLane[raceNumber][lane].seed;
        speed = _raceLane[raceNumber][lane].speed;
        max = _raceLane[raceNumber][lane].max;
        settled = _raceLane[raceNumber][lane].settled;
    }

    function getRacer (uint id) external view 
        returns (
            uint lastRace,
            uint8 accel,
            uint8 top,
            uint8 traction
        ) {
        lastRace = _racerLastRace[id];
        accel = _racerAcceleration[id];
        top = _racerTopSpeed[id];
        traction = _racerTraction[id];
    }

    function getRaceQueue (uint16 level) external view returns (uint) { 
        return ((_raceQueue[level] == 0) ? 0 : _lanesReady[_raceQueue[level]]);
    }

    function numSettling() external view returns(uint256 count) {
        count = (_lastSettling + 1) - _firstSettling;
    }
    
    function experienceOf(address account) external view returns(uint256 experience) {
        experience = _accountExp[account];
    }

    function settleNextLane (uint256 raceNumber) internal { 
        uint8 nextLane = _lanesSettled[raceNumber] + 1;
        (
        uint32 distance,
        uint16 split,
        uint8 randExp
        ) = processLane (
            _race[raceNumber].start, 
            _race[raceNumber].distance, 
            _raceLane[raceNumber][nextLane]
        );
        _raceLane[raceNumber][nextLane].distance = distance;
        _raceLane[raceNumber][nextLane].split = split;
        _raceLane[raceNumber][nextLane].exp = (
            (randExp >= 245)? 3: (randExp >= 205)? 2: 1
        );
        _lanesSettled[raceNumber] = nextLane;
        _raceLane[raceNumber][nextLane].settled = true;
    
        if (_lanesSettled[raceNumber] == 1){
            _settleQueue[++_lastSettling] = raceNumber;
            msg.sender.transfer (FIRST_SETTLER_REWARD);
        } else msg.sender.transfer (SETTLER_REWARD);
    
        emit LaneSettled (
            msg.sender,
            raceNumber, 
            _lanesSettled[raceNumber], 
            now
        );
    }
    
    function processLane (uint256 startBlock, uint32 raceLength, Lane storage lane) internal view returns (
        uint32 distance, 
        uint16 finishSplit, 
        uint8 randExp
    ) { 
        uint8 blockIndex;
        bytes32 hash;
        uint8 split;
        uint16 speed;
        while (startBlock + blockIndex <= block.number && distance < raceLength) {
            hash = keccak256 (abi.encodePacked (
                lane.seed,
                blockhash(startBlock + blockIndex)
            ));
            split = 0;
            while (split < 32 && distance < raceLength) {
                speed = lane.speed + uint8 (hash[split]);
                distance = ((speed >= lane.max)? 
                    distance + lane.max : distance + speed);
                if (distance >= raceLength) {
                    finishSplit = blockIndex * 32 + split + 1;
                    randExp = uint8 (hash[split]);
                }
                split++;
            }
            blockIndex++;
        }
    }
    
    function settleFinish (uint256 raceNumber) internal { 
        uint8[LANE_COUNT] memory finish = finishRace (raceNumber);
        uint8 place;
        address ownerAddress;
        address payable owner;
        for (uint8 lane=1; lane<=LANE_COUNT; lane++) {
            place = (
                (lane == finish[0]) ? 1 :
                (lane == finish[1]) ? 2 :
                (lane == finish[2]) ? 3 :
                (lane == finish[3]) ? 4 :
                (lane == finish[4]) ? 5 : 6
            );
            ownerAddress = _entity.ownerOf(_raceLane[raceNumber][lane].id);
            if (ownerAddress != address(0)) {
                _accountExp[ownerAddress] += _raceLane[raceNumber][lane].exp;
                owner = address(uint160(ownerAddress));
                if (place == 1) 
                    owner.transfer (firstPlaceReward(_race[raceNumber].level));
                else if (place == 2) 
                    owner.transfer (secondPlaceReward(_race[raceNumber].level));
                else if (place == 3) 
                    owner.transfer (thirdPlaceReward(_race[raceNumber].level));
            }
            emit RaceFinished (
                ownerAddress, 
                _raceLane[raceNumber][lane].id, 
                raceNumber, 
                place, 
                _raceLane[raceNumber][lane].split, 
                _raceLane[raceNumber][lane].distance,
                now
            );
        }
        _lanesFinish[raceNumber] = finish;
        _race[raceNumber].settled = true;
        removeRaceSettling(raceNumber);
        msg.sender.transfer (LAST_SETTLER_REWARD);
        emit RaceSettled (
            msg.sender,
            raceNumber, 
            now
        );
    }

    function finishRace (uint256 raceNumber) 
        internal view returns (uint8[LANE_COUNT] memory finish) {
            
        finish = [0,0,0,0,0,0];
        uint8 f;
        uint8 l;
        bool placed;
        uint32 distance;
        uint16 split;
        for (uint8 lane=1; lane<=LANE_COUNT; lane++) {
            distance = _raceLane[raceNumber][lane].distance;
            split = _raceLane[raceNumber][lane].split;
            f = 0;
            placed = false;
            while (f < LANE_COUNT && !placed) {
                if (finish[f] == 0) {
                    finish[f] = lane;
                    placed = true;
                } 
                else if (split < _raceLane[raceNumber][finish[f]].split ||
                    (split == _raceLane[raceNumber][finish[f]].split && 
                        distance > _raceLane[raceNumber][finish[f]].distance)
                ) {
                    //shift any prev finished lanes down first
                    l = LANE_COUNT-1;
                    while (l > f) {
                        //if(finish[_l-1] != 0){
                            finish[l] = finish[l-1];
                        //}
                        l--;
                    }
                    finish[f] = lane;
                    placed = true;
                }
                f++;
            }
        }
    }
    
    function refundExpiredRace (uint raceNumber) internal {
        uint refund = raceCost (_race[raceNumber].level) - SETTLER_FEE;
        uint reward = 0;
        address ownerAddress;
        address payable owner;
        for (uint8 lane=1; lane<=LANE_COUNT; lane++) {
            if (_raceLane[raceNumber][lane].id != 0) {
                ownerAddress = _entity.ownerOf(_raceLane[raceNumber][lane].id);
                if (ownerAddress != address(0)){
                    owner = address(uint160(ownerAddress));
                    owner.transfer(refund);
                }                
                reward += SETTLER_FEE;
                emit RaceFinished (
                    ownerAddress, 
                    _raceLane[raceNumber][lane].id, 
                    raceNumber, 
                    0, 
                    0, 
                    0,
                    now
                );
            }
        }
        _race[raceNumber].settled = true;
        removeRaceSettling(raceNumber);
        if (reward > 0) msg.sender.transfer(reward);
        emit RaceSettled (
            msg.sender,
            raceNumber, 
            now
        );
    }

    function removeRaceSettling(uint raceNumber) internal {
        if (_settleQueue[_firstSettling] == raceNumber) {
            delete _settleQueue[_firstSettling++];
        } else if(_settleQueue[_lastSettling] == raceNumber) {
            delete _settleQueue[_lastSettling--];
        } else {
            uint index = _firstSettling;
            bool found = false;
            while (_lastSettling >= index && !found) {
                if (_settleQueue[index] == raceNumber) {
                    found = true;
                }else index++;
            }
            if (found) {
                _settleQueue[index] = _settleQueue[_lastSettling];
                delete _settleQueue[_lastSettling--];
            }
        }
    }

    /* INTERNAL PURE */
    
    function firstPlaceReward (uint16 level) internal pure returns (uint cost) { 
       cost = FIRST_BASE + (level * FIRST_MULT);
    }
    function secondPlaceReward (uint16 level) internal pure returns (uint cost) { 
       cost = SECOND_BASE + (level * SECOND_MULT);
    }
    function thirdPlaceReward (uint16 level) internal pure returns (uint cost) { 
       cost = THIRD_BASE + (level * THIRD_MULT);
    }
    function racerLevel (uint8 accel, uint8 top, uint8 traction) 
        internal pure returns (uint16 level) { 
        uint16 count = accel + top + traction;
        level = ((count < 8) ? 0 : count / 8);
    }
    function raceDistance (uint16 level) internal pure returns (uint32 distance) { 
       distance = DISTANCE_BASE + ((level * LEVEL_DISTANCE_GAIN) * AVG_RACE_SPLITS);
    }
    function raceCost (uint16 level) internal pure returns (uint cost) { 
       cost = SETTLER_FEE + ((level * COST_MULT) + COST_BASE);
    }
    function levelValue (uint16 level) internal pure returns (uint value) { 
        value = (level == 0) ? 0 :
            (level * 8 * (raceCost(level-1) - SETTLER_FEE)) +
                levelValue (level-1);
    }
    function nextTrackConditions (uint8 trackConditions, uint8 weather) internal pure 
        returns (uint8) { return (
            (weather >= 250 && trackConditions < 253)? trackConditions + 3 : 
            (weather >= 235 && trackConditions < 254)? trackConditions + 2 : 
            (weather >= 195 && trackConditions < 255)? trackConditions + 1 : 
            (weather <= 5 && trackConditions > 3)? trackConditions - 3 : 
            (weather <= 20 && trackConditions > 2)? trackConditions - 2 : 
            (weather <= 60 && trackConditions > 1)? trackConditions - 1 : 
            trackConditions
        );
    }
    function initRacer (uint8 accel, uint8 top, uint8 traction, uint8 trackConditions) 
        internal pure returns (uint16 speed, uint16 max) {
        speed = (SPEED_BASE + accel) * SPEED_MULT;
        max = ((SPEED_BASE + top) * SPEED_MULT) + MAX_DIFF;
        if (traction < trackConditions) {
            uint32 frictionNom = traction + FRICTION_BASE;
            uint32 speedNom = frictionNom * speed;
            uint32 maxNom = frictionNom * max;
            uint32 frictionDenom = trackConditions + FRICTION_BASE;
            speed = uint16(speedNom / frictionDenom);
            max = uint16(maxNom / frictionDenom);
        }
    }
}