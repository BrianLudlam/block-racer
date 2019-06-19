pragma solidity ^0.5.8;
import "./ERC721.sol";
import "./IERC721Entity.sol";

/**
 * @title Contract ERC721Entity is ERC721, and implements IERC721Entity
 * @author Brian Ludlam
 * 
 * ERC721Entity Contract defines a standard ERC721 token, and then extends the 
 * functionality to give entity-type properties and functionality. An entity is
 * defined here as a unique non-fungible token having: owner-mutable name, immutable 
 * age, immutable traceable lineage, and immutable genes propagated with both randomness
 * and rarity. Entity creation requires two transactions total: First createEntity is 
 * called by the intended owner, which places the entity into a spawning pool with a 
 * pre-determined spawn block. After that, someone calling spawnEntity on or after the entity's 
 * spawn block, will spawn that entity, giving it genes. Genes are applied using the 
 * randomness of the pre-determined spawn block's hash combined with it's blind 
 * semi-random spawner. 
 * 
 * Entity Creation
 * 
 * Creating an entity starts with calling createEntity, with a name and optional
 * parents. If no parents are given, the entity will be spawned with random rarity
 * genes. If parents given, the entity will be spawned with random combinatorial genes.
 * Each successful call to createEntity will cost 4 finney, which is payed in-full 
 * indirectly to the future spawner of the created entity.
 * 
 * Entity Genes
 * 
 * Entity Genes are specified as 32 8bit (0-255) values, which can be used as
 * a property such as hair color, or as the entity's "potential"
 * in some activity, for example: max movement speed or strength. The applied
 * genes must have both randomness and rarity. Randomness is achieved in this 
 * implementation by either: Random Rarity Propagation, when created without 
 * parents, or Random Combinatorial Propagation, when created with parents. 
 * Both use a pre-determined future block hash, combined with blind 
 * semi-random spawning, to achieve randomness.
 * 
 * Random Rarity Propagation
 * 
 * With Random Rarity Propagation an entity is spawned, without parents, 
 * randomly giving it an exponentially curved set of possible gene values. 
 * Roughly half of all gene values spawned will be between 32 and 64, 
 * with each value above that being increasingly more rare. Maximum rarity for a 
 * single gene is 1:256, representing max gene value of 255. Getting all 32 genes
 * at 255, has odds of 1:256^32, a 77 digit number, relatively impossible.
 * 
 * Random Combinatorial Propagation
 * 
 * With Random Combinatorial Propagation an entity has parents, and therefore
 * spawned with random gene values - between the values' of each of it's parents'
 * genes. The min gene resulting value, will always be the lower of the two parent
 * genes, and the higher of the two parent genes being the max, of any specific
 * gene being randomized in-between those parent gene values.
 * 
 * Entity Lineage
 * 
 * With each entity having either 2 parents or null parents, any entity's origin
 * can be traced back to null parent end-nodes, creating a provable tree of lineage.
 * An entity can never have only one null parent, either both null/zero, or both 
 * existing/traceable entities.
 * 
 * Entity Spawning
 * 
 * Once created using createEntity, an entity goes into a spawning pool with 
 * a pre-determined spawn block and zeroed/null genes. On or after that 
 * pre-determined spawn block, spawnEntity can be called to spwan the entity, 
 * providing it with genes. Transaction spawnEntity can be called by anyone
 * at any time, spawning the next queued spawn that is ready. Each successful call 
 * to spawnEntity pays 4 finney, payed indirectly by a previous caller of 
 * createEntity. If no spawns in queue, or none that are ready to spawn left on the 
 * block being called on, transaction will fail at minimal cost (~1/5 finney.)
 * If 5 spawnEntity transactions occur on the same block, and only 4 spawns are
 * ready on that block, the fifth call will fail. 
 * 
 * Entity Renaming
 * 
 * Entity owner can rename entity at any time by calling nameEntity, for 
 * example, renaming an entity after purchasing it from someone else. Entity 
 * name will always be chopped at a 32 byte max.
 * 
 * Entity Expiration
 *
 * Given the Ethereum block-history-limit of 256 blocks, if a spawning entity 
 * reaches 255 blocks from pre-determined spawn block without being spawned, that 
 * entity's spawning becomes expired. An expired entity, cannot be spawned and 
 * therefore has permanently zeroed genes. Spawning is blind to the spawner, and 
 * queued in order, so for an entity to become expired, a full-stop in spawning 
 * must occur for 255 blocks, which should be relatively rare. If an entity creator 
 * is the only spawning force currently in play, it is their responsibility to spawn 
 * entities they have created. Claiming spawning reward, plays a more major role in 
 * motivating spawning activity of course. A call to spawnEntity, with expired spawn 
 * next in queue, still pays the spawner as always, but will result in a cheaper 
 * transaction, so expired spawns are never a penalty to spawner (to avoid backlog 
 * of expired spawns of any kind.) The number of entities ready to spawn, can be 
 * determined on any block, by calling spawnCount.
 * 
 * Note on Block Hash Randomness
 * 
 * Obviously pseudo-random, and miner generated, but relatively random enough for 
 * it's given purpose. Miners have some control over block hash creation, but the 
 * process involves GPUs trying millions of nonces per second each translating into 
 * a different block hash. Once a nonce result hits the target difficulty, the new 
 * block immediately propagates in attempt to win the block creation reward. Any 
 * additional "rerolling" of nonce attempts and/or reordering transactions to find 
 * a more desirable resulting hash value exponentially adds risk of losing the block 
 * creation reward. Therefore, all block hash random values used must not translate 
 * into potential value over block reward, currently 3+ Eth, to ensure it's never 
 * worth it for miners to take that risk. Even if they do, it amounts to a series 
 * of re-rolls, and never direct control over exact block hash value. 
 * 
 * Miners also control transaction ordering, which can effect outcome to some degree, 
 * but not enough to cause any significant advantage or adverse disadvantage. Future 
 * block hash value (as opposed to current block hash) is used for two reasons: allows 
 * a built-in 12 block transaction verification process, and prevents any kind of 
 * read-ahead checking of block hash value by miners on any given block. All block 
 * hashes used are combined with integral data, so there is no block hash rooted value 
 * that effects any state values directly. In the case of spawning, in this implementation, 
 * an exact spawn block - 12 blocks into the future - is set during the createEntity call, 
 * and then the spawn block's hash is combined with unique entity id and spawner address 
 * during the spawnEntity call. 
 * 
 */
contract ERC721Entity is ERC721, IERC721Entity {

    //number of blocks to cast spawning into future = relatively verified = 12 blocks
    uint8 private constant SPAWN_BLOCKS = 12;
    //4 finney - transferred from creator to spawner
    uint256 private constant SPAWN_FEE = 4000000000000000;
    
    //Parent ids of entity, zeroes if no parents.
    struct Parents {//immutable
        uint256 a;
        uint256 b;
    }
    
    //contract developer, power to destroy/upgrade
    address payable private _developer;
    
    //Mapping to entity parents. Immutable
    mapping (uint256 => Parents) private _parents;
    
    //Mapping to entity spawn block number before spawn, then 
    //spawn block timestamp after spawn. Immutable
    mapping (uint256 => uint256) private _born;
    
    //Mapping to entity genes. Immutable
    mapping (uint256 => bytes32) private _genes;
    
    //Mapping to entity name. Mutable by owner
    mapping (uint256 => bytes32) private _name;
    
    //internal fifo spawn queue
    mapping(uint256 => uint256) private _spawnFarm;
    uint256 private _firstSpawn;//spawn queue first index
    uint256 private _lastSpawn;//spawn queue last index

    constructor() public { 
        _developer = msg.sender;
        _firstSpawn = 1;//init spawn queue
    }

    /**
     * Transaction createEntity - Create token entity with given name and optional parents. 
     * If parents are null, create new entity with random rarity genes, otherwise create 
     * entity with random combinatorial genes. Created entity will immediately enter 
     * spawning poolfor exactly 12 blocks, when it becomes ready for spawning. Use 
     * spawnEntity to spawn entity. Fee of 4 finney is collected by createEntity, 
     * and payed out to successful caller of spawnEntity.
     * @param name = name of entity, max 32 bytes
     * @param parentA = id of parentA entity, or zero
     * @param parentA = id of parentB entity, or zero
     * @dev name is no more than 32 bytes, string converted to bytes32.
     * Parents must be both caller owned entities or both zero.
     * TX FEE: 4 finney
     * GAS: ~130k-160k (no parents - with parents)
     */
    function createEntity(
        string calldata name, 
        uint256 parentA, 
        uint256 parentB
    ) external payable { 
        require (msg.value >= SPAWN_FEE, "Spawn fee not covered.");
        require (
            (parentA == 0 && parentB == 0) ||
            (parentA != parentB && 
            ownerOf(parentA) == msg.sender && 
            ownerOf(parentB) == msg.sender), "Invalid parents."
        );
        uint256 id = mintFor(msg.sender);
        _parents[id] = Parents(parentA, parentB);
        _born[id] = block.number + SPAWN_BLOCKS;//future spawn block
        _name[id] = toBytes32(bytes(name));//chop to 32 bytes
        _spawnFarm[++_lastSpawn] = id;
        if (msg.value > SPAWN_FEE) 
            msg.sender.transfer(msg.value - SPAWN_FEE);
    }
    
    /**
     * Transaction spawnEntity - Spawn next ready token entity. Entities are 
     * spawned blindly in the order they were created; first created, first spawned.
     * If no entities ready to spawn on block, transaction will fail. Use 
     * spawnCount to check current spawn count. Higher the spawn count, relatively 
     * lesser chance of fail. Successful spawning transaction pays out 4 finney, 
     * as payed by creator. Fail costs ~1/5 finney. Entity genes are zeroed until spawn. 
     * Spawn expires, giving it permanent zeroed genes, if not spawned within 255 
     * blocks of creation.
     * TX REWARD: 4 finney
     * GAS: ~70k
     */
    function spawnEntity() external { 
        require (
            _lastSpawn >= _firstSpawn && //has spawns
            block.number >= _born[_spawnFarm[_firstSpawn]], 
            "No spawns."
        );
        uint256 id = _spawnFarm[_firstSpawn];
        delete _spawnFarm[_firstSpawn++];
        //expired spawn if older than 255 blocks = owner penalty = genes remain 0x0
        if (block.number <= _born[id] + 255) {
            //unique entity id x blind spawner address x predetermined-block hash value
            bytes32 nature = keccak256(abi.encodePacked (
                id,
                msg.sender,
                blockhash(_born[id])
            ));
            //If parents are null, spawn with random rarity genes, else random propagate genes
            _genes[id] = (
                (_parents[id].a == 0 || _parents[id].b == 0) ? 
                    rarityGenes(nature) :
                    propagateGenes(
                        _genes[_parents[id].a], 
                        _genes[_parents[id].b], 
                        nature
                    )
            );
        }
        //switch *born* from birth block number to birth block timestamp
        _born[id] = now;
        msg.sender.transfer (SPAWN_FEE);
        emit Spawned (ownerOf(id), msg.sender, id);
    }
    
    /**
     * Transaction nameEntity - Name the given entity, by id. Owner only.
     * @param entity = id of entity
     * @param name = name of entity, max 32 bytes
     * GAS: ~35k
     */
    function nameEntity(uint256 entity, string calldata name) external {
        require (ownerOf(entity) == msg.sender);
        _name[entity] = toBytes32(bytes(name));//chop to 32 bytes
        emit NameChanged (msg.sender, entity, string (abi.encodePacked(_name[entity])));
    }
    
    /**
     * View nameOf Entity
     * @param entity = id of entity
     * @return name - name of entity as a string.
     */
    function nameOf(uint256 entity) external view returns (string memory name) {
        name = string (abi.encodePacked(_name[entity]));
    }
    
    /**
     * View ageOf Entity
     * @param entity = id of entity
     * @return age = spawn timestamp of entity, 
     * or zero if not spawned yet.
     */
    function ageOf(uint256 entity) external view returns (uint256 age) {
        age = ((_genes[entity] == 0x0) ? 0 : now - _born[entity]);
    }
    
    /**
     * View parentsOf Entity
     * @param entity = id of entity
     * @return parentA and @return parentB of entity, as two uint 
     * entity ids. Zeroes if null parents.
     */
    function parentsOf(uint256 entity) external view 
        returns (uint256 parentA, uint256 parentB) {
        parentA = _parents[entity].a;
        parentB = _parents[entity].b;
    }
    
    /**
     * View genesOf Entity
     * @param entity = id of entity
     * @return genes - genes of entity as an array of 
     * 32 8bit gene values (0-255) each.
     */
    function genesOf(uint256 entity) external view returns (uint8[] memory genes) {
        genes = decodeGenes(_genes[entity]);
    }

    /** TODO
     * View rarityOf Entity 
     * @return rarity of entity genes as percent
    function rarityOf(uint256 entity) external view returns (uint256 rarity) {
    }*/
    
    /**
     * View getEntity - returns all entity info
     * @param entity = id of entity
     * @return owner = entity owner
     * @return born = spawn timestamp of entity, 
     * @return parentA of entity, as uint, zero if none
     * @return parentB of entity, as uint, zero if none 
     * @return name - name of entity as a string.
     * @return genes - genes of entity as an array of 32 8 bit values
     */
    function getEntity(uint256 entity) external view returns (
        address owner,
        uint256 born,
        uint256 parentA,
        uint256 parentB,
        string memory name,
        uint8[] memory genes
    ) { 
        owner = ownerOf(entity);
        born =  _born[entity];
        parentA = _parents[entity].a;
        parentB = _parents[entity].b;
        name = string (abi.encodePacked(_name[entity]));
        genes = decodeGenes(_genes[entity]);
    }
    
    /**
     * View spawnCount 
     * @return count - number of spawns ready to spawn 
     * on current block.
     */
    function spawnCount() external view returns (uint256 count) {
        count = 0;
        while (
            _lastSpawn >= (_firstSpawn + count) &&
            block.number >= _born[_spawnFarm[_firstSpawn + count]]
        ) { count++; }
    }
    
    /* Testing only - remove from production or add proxy update-able interface */
    function destroy() external {
       require (_developer == msg.sender);
       selfdestruct(_developer);
    }
    
    /* Return to sender any abstract transfers */
    function () external payable { msg.sender.transfer(msg.value); }
    
    /* INTERNAL PURE */
    
    /**
     * @notice internal rarityGenes - get random rarity genes for spawning entity. 
     * @param nature - randomization source hash
     * @return genes for new entity.
     */
    function rarityGenes(bytes32 nature) internal pure 
        returns (bytes32 genes) { 
        bytes memory geneBytes = new bytes(32);
        uint8 rand;
        for (uint8 g=0; g<32; g++){
            rand = uint8 (nature[g]);
            geneBytes[g] = byte (
                randomRarityGenes (rand)
            );
        }
        genes = toBytes32(geneBytes);
    }
    
    /**
     * @notice internal propagateGenes - propagate genes from two given parents. 
     * @param genesA - genes of parent A. (order is insignificant)
     * @param genesB - genes of parent B. 
     * @param nature - randomization source hash
     * @return genes for new entity.
     */
    function propagateGenes(bytes32 genesA, bytes32 genesB, bytes32 nature) 
        internal pure returns (bytes32 genes) {
        bytes memory geneBytes = new bytes(32);
        uint8 gA;
        uint8 gB;
        uint8 rand;
        for (uint8 g=0; g<32; g++){
            gA = uint8 (genesA[g]);
            gB = uint8 (genesB[g]);
            rand = uint8 (nature[g]);
            geneBytes[g] = byte (
                (gA == gB) ? gA: 
                    (gA > gB) ? gB + (rand % (1 + gA - gB)) :
                        gA + (rand % (1 + gB - gA))
            );
        }
        genes = toBytes32(geneBytes);
    }
 
    /**
     * @notice internal decodeGenes - decode genes from bytes32 to array of 32 uint8s. 
     * @return genes as array of 32 uint8s.
     */
    function decodeGenes(bytes32 genes) internal pure 
        returns (uint8[] memory geneValues) { 
        geneValues = new uint8[](32);
        for (uint8 g=0; g<32; g++) {
            geneValues[g] = uint8 (genes[g]);
        }
    }
    
    /**
     * @notice internal randomRarityGenes - Gene rarity randomizer.
     * @param nature - uint8 randomization value
     * @return gene of random rarity.
     */
    //PROOF OF RARITY
    //TODO currently rough numerical sketch of exponential curve
    //redo with extact exponential curve translatable to exact rarity prob fig
    //32 - 255 (most common - most rare)
    //odds of 32-68 ~= 2:1 (50%)
    //odds of 255 = 256:1 (0.3%)
    //odds of 3x 255 = 256^3:1 = 16,777,216:1 (0.0000006%)
    function randomRarityGenes(uint8 nature) internal pure 
        returns (uint8 gene) {
        gene = ((nature % 8) + (8 * (
            (nature < 61) ? 4 :
            (nature < 102) ? 5 :
            (nature < 131) ? 6 :
            (nature < 147) ? 7 :
            (nature < 157) ? 8 :
            (nature < 165) ? 9 :
            (nature < 171) ? 10 :
            (nature < 177) ? 11 :
            (nature < 183) ? 12 :
            (nature < 189) ? 13 :
            (nature < 195) ? 14 :
            (nature < 201) ? 15 :
            (nature < 206) ? 16 :
            (nature < 211) ? 17 :
            (nature < 216) ? 18 :
            (nature < 221) ? 19 :
            (nature < 226) ? 20 :
            (nature < 230) ? 21 :
            (nature < 234) ? 22 :
            (nature < 238) ? 23 :
            (nature < 242) ? 24 :
            (nature < 245) ? 25 :
            (nature < 248) ? 26 :
            (nature < 251) ? 27 :
            (nature < 253) ? 28 :
            (nature < 254) ? 29 :
            (nature < 255) ? 30 : 31
        )));
    }
    
    /**
     * @notice internal toBytes32 - Convert byte array to bytes32
     * @param _data - bytes to convert.
     * @return data converted bytes32.
     */
    function toBytes32(bytes memory _data) internal pure 
        returns (bytes32 data) {
        if (_data.length == 0) return 0x0;
        assembly { data := mload(add(_data,32)) }
    }
}