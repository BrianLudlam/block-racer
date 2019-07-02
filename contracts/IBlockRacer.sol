pragma solidity ^0.5.8;

/**
 * @title BlockRacer Interface
 * @author Brian Ludlam
 * 
 * BlockRacer is a game allowing players (per Eth account) to compete against 
 * each other, by racing unique tokens around a blockchain racetrack. Players win
 * Eth by winning races, and potentially earn Eth by contributing to the settlement
 * of race results. Racing performance is part skill in training, and part 
 * randomness determined by blockhash creation over time. Racers increase level 
 * as they are trained, and are able to enter higher level races at higher levels. 
 * Higher level races cost more to enter and payout more to winners. Lower level 
 * races are more determined by randomness than training skill, and higher level 
 * races are more determined by training skill than randomness.
 * 
 * Racers
 * 
 * Racers are non-fungible token entities, following IERC721Entity,
 * which follows IERC721 and in turn IERC21. 
 * The two IERC721Entity functions interfaced are: ownerOf - returning 
 * the address of the racer's owner, and genesOf - returning an immutable 
 * array of 32 8bit genes determining the racer's training potential. 
 * Racers can: Race and Train. Training increases racer performance and 
 * racer level in following races. Racing icreasses player experience points. 
 * Player experience points are used to train racers.
 * 
 * Player Experience 
 * 
 * Player experience points are collected per account, by racing racers in races. 
 * Player experience is used to train account owned racers. For each racer 
 * in each race finished (regardless of placing), the racer's owner collects 
 * 1-3 experience points; 1 point most commonly, 2 at about 1:5 chance, 
 * and 3 about 1:50.
 * 
 * Training and Levels
 * 
 * Training costs player eperience points. Training involves increasing 3 main 
 * racer stats: acceleration, top speed, and traction. Racer level is always total 
 * training points / 8 (rounded down), so training automatically increases level.
 * Training a racer has no fee, and only requires ~70k gas. The maximum training 
 * a racer can have is determined by racer's genes, specifally the first 3 genes, 
 * used as: acceleration, top speed, and traction potrentials. Max training potential 
 * for each stat is 255.(8bit genes) Max training and max level are different for each 
 * racer, based on potential (genes), with overall max being 255 (rare) in all 
 * 3 stats, giving max level of 3 * 255 / 8 = 95 (extremely rare.)
 * 
 * Race Queue
 * 
 * Racer entity enters race queue, by id, at it's current level. Race queue is 6 deep for 
 * each level. A race starts once 6 racers (lanes), at the same level, are queued. Racer 
 * performance values are set permanantly upon entering race. Any training during race 
 * will not effect performance, or race level change, until next race. Racer can only be
 * in one race at a time. Racers may exit race queue, before race starts, but not after.
 * 
 * Race Cost / Fees
 * 
 * Race Entry Cost = Racing Fee + Settlement Fee
 * 
 * 100% of player fees collected are transfered to player contributors in the system.
 * 
 * The system has two fees: Settlement Fee and Racing Fee; both are collected
 * upon entering the race queue. Both are refunded upon exiting race queue. Settlement
 * fee is always the same at 4 finney per racer per race, consistantly payed out as 
 * rewards to those who settle each race. Racing fee is scaled by level, starting 
 * at 18 finney, increasing by 1.8 finney per level. Racing fees from each race are 
 * payed out as a reward to those who win/place that race: first, second, and third. 
 * After a race completes, all fees are payed out. Neither the contract, or the contract 
 * owner, retain any fees.
 * 
 * Race Process
 * 
 * A race begins once 6 racers of the same level are queued. The start of a race is
 * signified by setting the race's start block to the 12th block number from the 
 * block which processed the block start / the 6th racer being queued at a specific 
 * level. Each racer has performance variables set upon entry, and a performance seed,
 * which combined with each blockhash starting with the start block, will give a distance
 * travelled during that block. Each race has a set level-based distance to the finish 
 * line. Each block following start block provides a blockhash, translating into 
 * unique racer distance travelled during that block. This distance can be calculated
 * in parallel to the system (by a UI) to show race progress and result, without any
 * transactions needed to keep the race going. Once started, the race goes until all
 * racers reach the finish line. In order to "settle" the race - payout both player
 * experience and winner rewards to all racer owners, as well as claim settlement 
 * rewards - players can run the settleRace function.
 * 
 * Race Settlement 
 * 
 * Settlers are required to settle each race. Anyone can contribute to, and profit from,
 * the settling of any race. Each race requires 7 settlement transactions: 1 for each 
 * of 6 lanes, and one more to finalize the race result and payout winners. The gas 
 * needed to finalize a race is ~340k and pays 5 finney. The first settler is 
 * the next most expensive at ~300k, so pays out 4 finney. The middle settlers (lanes 2-6) 
 * are all about ~250k, each payout 3 finney. Settlement order is first come 
 * first served per race, and settlement transactions without a race to settle will 
 * fail, costing ~1/5 finney. The reward for settling a race is ~15-20 times
 * the cost of a failed settlement, so relatively efficient for high competition and 
 * scheduled automation. Trying to settle a race before it finishes (all racers reach
 * finish-line/ race distance) will also fail. Before allowing failed settlement, the 
 * system will first try to provide race settlers with any other possible race to settle 
 * before failing, to reduce failures. Note, the system is not aware of a race being
 * ready to settle until the first settlement transaction occurs. The system does not know
 * anything about any race result, until informed through settlement transactions. After 
 * a first settlement transaction is received for a race, the system is able to reroute
 * settlers to that race, upon potential fail in settling intended race. For example, if 8 
 * transactions to settle the same race occur all at the same time on one block. The 
 * first 7 will be successful and the 8th will potentially fail. However, if there is 
 * another race available to settle, the 8th settler will be rerouted to settle that
 * other race instead, etc. A failure only potentially occurs if there are no races
 * to settle; all races being either already settled or not finished yet.
 * 
 * Race Expiration
 * 
 * Once a race has started, it's result is determined by the next 5-10 blockhashs.
 * Given the block history limit of 256 blocks in Ethereum, after 256 blocks a race - 
 * whether settled or not - becomes expired, and can no longer be settled or "replayed."
 * When a race becomes expired before being fully settled, the following settlement
 * that comes in, will refund all racers' Racing Fees, and settler will collect all
 * 24 finney of the race's settlement rewards. This encourages racers to take 
 * responisiibity of settling own races, as well as max reward for settlers of
 * expired races, in order prevent any backlog of expired races (and refunding of fees 
 * collected). When a race becomes expired after being settled, it can no longer be 
 * replayed by a UI, due to the Eth block history limit, however if a history preserved 
 * (within UI, Oracle, or other contract) a blockhash history going back further 
 * than 256 blocks would allow potentially any race to always be replayable by UI. 
 * However, expired races that are not settled can never be settled internally by the
 * system with accurate results, due to Eth history limit, hence refund.
 * 
 * Track Conditions
 * 
 * Each race starts with specific track conditions (wet vs dry) according to an
 * accumulative random weather pattern shifting betweeen 1 (most dry) and 255 
 * (most wet/muddy.) Each race has a random chance to increment or decrement by 1-3, 
 * or remain the same. Racer's traction training allieviates track condition 
 * speed penalty.
 * 
 */
 
/**
 * @title Interface IBlockRacer
 * @author Brian Ludlam
 * date May 5, 2019
 */
interface IBlockRacer {
    /**
     * function enterRaceQueue - TX - Enter racer by id, into race queue by level.
     * @param id is racer id. Must be owner of entity.
     * @notice Once 6 racers are queued at any given level, race will start.
     * Racer must not already be racing (or in race queue)
     * Racer level = total training points / 8, rounded down.
     * Racing fee = 18 finney + (Racer Level * 1.8 finney)
     * Settlement Fee = 4 finney.
     * Race Entry Fee = Racing fee + Settlement Fee.
     * GAS = (
     *      first lane - create race and queue - ~210k, 
     *      lane 2-5 - queue - ~130k, 
     *      last lane - queue and start race - ~140k
     * ) *first per account will be slightly more
     */
    function enterRaceQueue (uint256 id) external payable;
    
    /**
     * function exitRaceQueue - TX - Exit racer by id, from current race queue. 
     * @param id is racer id. Must be owner of.
     * @notice Racer must be in race queue and race not already started, 
     * or will fail; otherwise will dequeue racer and refund fees 
     * to owner. If 6th racer at level enters queue before exit
     * transaction, race immediately starts, and exit will fail.
     * Race Exit Refund = Racing fee
     * GAS = ~35k - ~75k (depending on lane position)
     */
    function exitRaceQueue (uint256 id) external;
    
    /**
     * function settleRace - TX - Settle race by id, or fallback to the next 
     * @param race is race number to settle. 
     * @notice May be rerouted to diff race in settlement queue. If no races available
     * to settle, including any attempts to settle a race that has not yet finished, 
     * will fail. Successful race settlements will payout, first come first serve 
     * transaction order, according to gas costs of settlement steps. Seven settlement 
     * transactions are required for each race in total. The last being the most 
     * expensive ~375k pays out 5 finney, the first settlement being the next highest 
     * gas cost at ~240k paying out 4 ginney, and each of settlements 2-6 with gas 
     * cost ~185k pay out 3 finney each.
     * REWARD = (
     *      settle first lane - 4 finney, 
     *      settle lanes 2-6 - 3 finney, 
     *      settle race - 5 finney
     * )
     * GAS = (
     *      settle first lane - ~230k, 
     *      settle lanes 2-6 - ~190k, 
     *      settle race - ~350k
     * )
     */
    function settleRace (uint256 race) external;
    
    /**
     * function train - TX - Train racer by id. 
     * @param id is racer id. Must be owner of.
     * @param training is array of 3 8bit (0-255) values representing 3 training amounts.
     * @notice If training amount total is more than player (account) aexperience points,
     * or over the potential (genes) of the racer on any of the 3 amounts, will fail.
     * GAS = ~70k *first per account will be ~100k
     */
    function train (uint256 id, uint8[] calldata training) external;
    
    /**
     * Event RaceEntered - Fired during enterRaceQueue transaction, to signify racer
     * has entered race queue successfully.
     * @return owner = address of racer owner
     * @return racer = IERC721Entity id, unique 256 bit
     * @return race = race number, unique 256 bit
     * @return level = race level
     * @return lane = Racer's Lane # = 1 - 6
     */
    event RaceEntered (
        address indexed owner,
        uint256 indexed racer, 
        uint256 indexed race, 
        uint16 level,
        uint8 lane,
        uint256 timestamp
    );
    
     /**
     * Event RaceExited - Fired during exitRaceQueue transaction, to signify racer
     * has exited race queue successfully.
     * @return owner = address of racer owner
     * @return racer = IERC721Entity id, unique 256 bit
     * @return race = race number, unique 256 bit
     * @return level = race level
     * @return lane = Racer's previous lane # = 1 - 6
     */
    event RaceExited (
        address indexed owner, 
        uint256 indexed racer, 
        uint256 indexed race, 
        uint16 level,
        uint8 lane,
        uint256 timestamp
    );
    
    /**
     * Event RaceStarted - Fired during enterRaceQueue transaction, to signify 
     * the 6th racer has enter race queue at level, and race is started.
     * @return race = race number, unique 256 bit
     * @return level = race level
     * @return distance = distance to finish line, determined by level.
     * @return conditions = race track conditions (0-255)
     */
    event RaceStarted (
        uint256 indexed race, 
        uint16 level,
        uint32 distance,
        uint8 conditions,
        uint256 timestamp
    );
    
    /**
     * Event LaneSettled - Fired duirng settleRace transaction, to signify 
     * successful lane settlement of a race. 6 total events will occur per race,
     * one for each of 6 lanes requiring settlement. Te final settlement transaction
     * fires RaceSettled event.
     * @return race = race number, unique 256 bit
     * @return settler = Address of settler (settleRace caller)
     * @return lane = Settled lane # = 1 - 6
     */
    event LaneSettled (
        address indexed settler, 
        uint256 indexed race, 
        uint8 lane, 
        uint256 timestamp
    );
    
    /**
     * Event RaceSettled - Fired duirng settleRace transaction, to signify 
     * successful final settlement of a race. 1 total events will occur per race.
     * @return race = race number, unique 256 bit
     * @return settler = Address of settler (settleRace caller)
     */
    event RaceSettled (
        address indexed settler, 
        uint256 indexed race, 
        uint256 timestamp
    );
    
    /**
     * Event RaceFinished - Fired duirng settleRace transaction, per each 6 lanes, 
     * to signify successful race finish by racer. 6 total events will occur per race.
     * @return owner = address of racer owner
     * @return racer = IERC721Entity id, unique 256 bit
     * @return race = race number, unique 256 bit
     * @return level = race level
     * @return place = Racer's resulting place in race finish 1st - 6th = 1 - 6
     * @return splits = Racer's resulting split "time" = 32 splits per block.
     * @return distance = Racer's resulting distance raced.
     * @return exp = Experience gained during race.
     * @notice (total) distance / (total) splits = avg distance per split
     */
    event RaceFinished (
        address indexed owner, 
        uint256 indexed racer, 
        uint256 indexed race, 
        uint16 level,
        uint8 place, 
        uint16 splits, 
        uint32 distance,
        uint8 exp,
        uint256 timestamp
    );
    
    /**
     * Event RacerTrained - Fired duirng train transaction to signify 
     * successful racer training session. 
     * @return owner = address of racer owner
     * @return racer = IERC721Entity id, unique 256 bit
     * @return acceleration = amount of acceration training.
     * @return topSpeed = amount of topSpeed training.
     * @return traction = amount of traction training.
     */
    event RacerTrained (
        address indexed owner, 
        uint256 indexed racer,
        uint8 acceleration,
        uint8 topSpeed,
        uint8 traction,
        uint256 timestamp
    );
    
    /**
     * function getRace - READ ONLY - Get race info
     * @param raceNumber = race number to get.
     * @return start = starting block of race. All blocks after calc result until finish
     * @return level = Races seperated and determined by entering racer levels.
     * @return distance = Race distance to finish line.
     * @return conditions = Race track conditions. 1 = dryest, 255 = wetest/muddiest
     * @return lanesReady = Number of lanes with racers ready. Racers come and go until start
     * @return lanesSettled = Number of and order of lanes settled.
     * @return settled = Race settled flag
     * @return racers = array of racer ids of racers queued or racing.
     * @return finish = Race finish results, empty until race settled, then
     * array of 6 racer ids ordered by place 1st..6th [id in 1st,id in 2nd,...,id in 6th]
     */
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
    );
    
    /**
     * function getRaceLane - READ ONLY - Get race lane info
     * @param raceNumber = race number to get.
     * @param lane = lane number to get in race.
     * @return id = racer id in lane
     * @return seed = racer's race seed
     * @return speed = racer's race speed constant
     * @return max = racer's race max speed constant
     * @return settled = race lane settled flag
     * @notice This is all that is needed to calc race result, and any split,
     * given race blockhash history
     */
    function getRaceLane (uint raceNumber, uint8 lane) external view returns (
        uint256 id, 
        bytes32 seed, 
        uint16 speed, 
        uint16 max, 
        bool settled
    );
    
    /**
     * function getRacer - READ ONLY - Get racer info
     * @param id = racer id to get.
     * @return lastRace = last race raced by racer, 0 if none or previously exited race queue
     * @return accel = accerlation training amount
     * @return top = top speed training amount
     * @return traction = traction training amount
     */
    function getRacer (uint id) external view returns (
        uint lastRace,
        uint8 accel,
        uint8 top,
        uint8 traction
    );
    
    /**
     * function getRaceQueue - READ ONLY - Get race queue for specific level
     * @param level = race queue level to check
     * @return number of racers queued at level on current block.
     * @notice Result will always be 0-5, with the 6th always starting the race,
     * and immediately reseting the level queue to 0.
     */
    function getRaceQueue (uint16 level) external view returns (uint);
    
    /**
     * function numSettling - READ ONLY - Get number of races currently being settled.
     * @return count as number of races currently being settled.
     * @notice A race is being settled, if at least one settlement transaction has occured,
     * and the race is still not fully settled. Each race requires 7 settlements total.
     * The higher the number, the relatively safer it is to attempt settlement
     * given more races that need settlement at that time. Assume competition.
     */
    function numSettling() external view returns(uint256 count);
    
    /**
     * function experienceOf - READ ONLY - Get current unused experience amount of 
     * player account.
     * @param account of owner
     * @return experience amount of account.
     */
    function experienceOf(address account) external view returns(uint256 experience);
}