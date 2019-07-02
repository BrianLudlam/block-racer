pragma solidity ^0.5.8;

/**
 * @title IERC721Entity - ERC721Entity Interface - Non-fungible token extension interface, 
 * adding entity properties of: name, age, genes, parents/lineage, and blind spawning pool 
 * functionality to existing ERC721 token functionality.
 * @author Brian Ludlam
 */
interface IERC721Entity {
    
    /**
     * Transaction createEntity - Create NFT entity with name and optional parents.
     * @param name = string name of entity, max 32 bytes
     * @param parentA = id of parentA entity, or zero/null
     * @param parentB = id of parentB entity, or zero/null
     */
    function createEntity(
        string calldata name, 
        uint256 parentA, 
        uint256 parentB
    ) external payable;
    
    /**
     * Transaction spawnEntity - Spawn next ready NFT entity. Entities are 
     * spawned blindly in the order they were created; first created, first spawned.
     * An entity does not have genes (zeroed genes) until spawned. 
     */
    function spawnEntity() external;
    
    /**
     * Transaction nameEntity - Name the given entity, by id. Owner only.
     * @param entity = id of entity
     * @param name = name of entity, max 32 bytes
     */
    function nameEntity(uint256 entity, string calldata name) external;

    /**
     * View nameOf Entity
     * @param entity = id of entity
     * @return name - name of entity as a string.
     */
    function nameOf(uint256 entity) external view returns (string memory name);
    
    /**
     * View ageOf Entity
     * @param entity = id of entity
     * @return age = spawn timestamp of entity, 
     * or zero if not spawned yet.
     */
    function ageOf(uint256 entity) external view returns (uint256 age);
    
    /**
     * View parentsOf Entity
     * @param entity = id of entity
     * @return parentA and @return parentB of entity, as two uint 
     * entity ids. Zeroes if null parents.
     */
    function parentsOf(uint256 entity) external view returns (
        uint256 parentA, 
        uint256 parentB
    );
    
    /**
     * View genesOf Entity
     * @param entity = id of entity
     * @return genes - genes of entity as an array of 
     * 32 8bit gene values (0-255) each.
     */
    function genesOf(uint256 entity) external view returns (
        uint8[] memory genes
    );

    /** TODO
     * View rarityOf Entity 
     * @returns rarity of entity genes as percent
    function rarityOf(uint256 entity) external view returns (uint256 rarity);
    */
    
     /**
     * View getEntity - returns all entity info
     * @param entity = id of entity
     * @return owner = entity owner
     * @return born = spawn timestamp of entity, 
     * @return parentA of entity, as uint, zero if none
     * @return parentB of entity, as uint, zero if none 
     * @return name of entity as a string.
     * @return genes genes of entity as an array of 32 8 bit values
     */
    function getEntity(uint256 entity) external view returns (
        address owner, 
        uint256 born, 
        uint256 parentA, 
        uint256 parentB,
        string memory name, 
        uint8[] memory genes
    );
    
    /**
     * View spawnCount 
     * @return count - number of spawns ready to spawn 
     * on current block.
     */
    function spawnCount() external view returns (uint256 count);
    
    /**
     * Event Spawned - Fired during spawnEntity transaction after entity is spawned.
     * @return owner = entity owner
     * @return entity = entity id
     * @return spawner = entity spawner (spawnEntity caller)
     */
    event Spawned(
        address indexed owner, 
        address indexed spawner,
        uint256 indexed entity,
        uint256 timestamp
    );
    
    /**
     * Event NameChanged - Fired during nameEntity transaction after entity is renamed.
     * @return owner = entity owner
     * @return entity = entity id
     * @return name = new name
     */
    event NameChanged(
        address indexed owner, 
        uint256 indexed entity, 
        string name,
        uint256 timestamp
    );
}