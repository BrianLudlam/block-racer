# BlockRacer Contract

BlockRacer is a game allowing players (per Eth account) to compete against each other, by racing unique tokens around a block-driven racetrack. Players win Eth by winning races, and potentially earn Eth by contributing to the settlement of race results. Racing performance is part skill in training, and part randomness determined by block hash creation over time. Racers increase level as they are trained, and are able to enter higher level races at higher levels. Higher level races cost more to enter and payout more to winners. Lower level races are more determined by randomness than training skill, and higher level races are more determined by training skill than randomness.

## Racers

Racers are non-fungible token entities, following IERC721Entity, which follows IERC721 and in turn IERC21. The two IERC721Entity functions interfaced are: ownerOf - returning the address of the racer's owner, and genesOf - returning an immutable array of 32 8bit genes determining the racer's training potential. Racers can: Race and Train. Training increases racer performance and racer level in following races. Racing increases player experience points. Player experience points are used to train racers.

## Player Experience 

Player experience points are collected per account, by racing racers in races. Player experience is used to train account owned racers. For each racer in each race finished (regardless of placing), the racer's owner collects 1-3 experience points; 1 point most commonly, 2 at about 1:5 chance, and 3 about 1:50.

## Training and Levels

Training costs player experience points. Training involves increasing 3 main racer stats: acceleration, top speed, and traction. Racer level is always total training points / 8 (rounded down), so training automatically increases level. Training a racer has no fee, and only requires ~70k gas. The maximum training a racer can have is determined by racer's genes, specially the first 3 genes, used as: acceleration, top speed, and traction potentials. Max training potential for each stat is 255.(8bit genes) Max training and max level are different for each racer, based on potential (genes), with overall max being 255 (rare) in all 3 stats, giving max level of 3 * 255 / 8 = 95 (very rare ~17Mil:1)

## Race Queue

Racer entity enters race queue, by id, at it's current level. Race queue is 6 deep for each level. A race starts once 6 racers (lanes), at the same level, are queued. Racer performance values are set permanently upon entering race. Any training during race will not effect performance, or race level change, until next race. Racer can only be in one race at a time. Racers may exit race queue before race starts, but not after.

## Race Cost / Fees

Race Entry Cost = Racing Fee + Settlement Fee

100% of player fees collected are transferred to player contributors in the system.

The system has two fees: Settlement Fee and Racing Fee; both are collected upon entering the race queue. Both are refunded upon exiting race queue before race starts. Settlement fee is always the same at 4 finney per racer per race, consistently payed out as rewards to those who settle each race. Racing fee is scaled by level, starting at 18 finney, increasing by 1.8 finney per level. Racing fees from each race are payed out as a reward to those who win/place that race: first, second, and third. After a race completes, all fees are payed out. Neither the contract, or the contract owner, retain any fees.

## Race Process

A race begins once 6 racers of the same level are queued. The start of a race is signified by setting the race's start block to the 12th block number from the block which processed the block start / the 6th racer being queued at a specific level. Each racer has performance variables set upon entry, and a performance seed, which combined with each block hash starting with the start block, will give a distance travelled during that block. Each race has a set level-based distance to the finish line. Each block following start block provides a block hash, translating into unique racer distance travelled during that block. This distance can be calculated in parallel to the system (by a UI) to show race progress and result, without any transactions needed to keep the race going. Once started, the race goes until all racers reach the finish line. In order to "settle" the race - payout both player experience and winner rewards to all racer owners, as well as claim settlement rewards - players can run the settleRace function after 24 blocks have past since the race started.

## Race Settlement 

Race Settlement is required to settle each race. Anyone can contribute to, and profit from, the settling of any race. Each race requires 7 settlement transactions: 1 for each of 6 lanes, and one more to finalize the race result and payout winners. The gas needed to finalize a race is the highest at ~350k so pays the most, 5 finney. The first settler is the next most expensive at ~230k, so pays out 4 finney. The middle settlers (lanes 2-6) are all about ~190k, each payout 3 finney. Settlement order is first come first served per race, and settlement transactions without a race to settle will fail, costing ~1/5 finney. The reward for settling a race is ~15-20 times the cost of a failed settlement, so relatively efficient for high competition and scheduled automation. Trying to settle a race before it finishes (all racers reach finish-line/ race distance) will also fail. Before allowing failed settlement, the system will first try to provide race settlers with any other possible race to settle before failing, to reduce failures. Note, the system is not aware of a race being ready to settle until the first settlement transaction occurs. The system does not know about any race result, until informed through settlement transactions. After the first settlement transaction is received for a race, the system is able to reroute other settlers to that race, upon potential fail in settling their intended race. For example, if 8 transactions to settle the same race occur all at the same time on one block. The first 7 will be successful and the 8th will potentially fail. However, if there is another race available to settle, the 8th settler will be rerouted to settle that other race instead, etc. A failure only potentially occurs if there are no races to settle; all races being either already settled or not finished yet.

## Race Expiration

Given the block history limit of 256 blocks in Ethereum, after 256 blocks a race - whether settled or not - becomes expired, and can no longer be settled or "replayed". When a race becomes expired before being fully settled, the following settlement that comes in, will refund all racers' Racing Fees, and settler will collect all 24 finney of the race's settlement rewards. This encourages racers to take responsibility of settling own races, as well as max reward for settlers of expired races, in order prevent any backlog of expired races (and refunding of fees collected). When a race becomes expired after being settled, it can no longer be replayed by a UI, due to the Eth block history limit, however if a history preserved (within UI, Oracle, or other contract) a block hash history going back further than 256 blocks would allow potentially any race to always be replayable by UI. However, expired races that are not settled can never be settled internally by the system with accurate results, due to Eth history limit, hence refund.

## Track Conditions

Each race starts with specific track conditions (wet vs dry) according to an accumulative random weather pattern shifting between 1 (most dry) and 255 (most wet/muddy.) Each race has a random chance to increment or decrement by 1-3, or remain the same. Racer's traction training alleviates track condition speed penalty.

## Usage with Truffle

clone repo
truffle compile
truffle test
truffle migrate

Author: Brian Ludlam