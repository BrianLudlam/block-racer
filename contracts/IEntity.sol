pragma solidity ^0.5.8;

/**
 * @title IEntity is IERC721Entity, IERC721, and IERC165 (convenience interface)
 * @author Brian Ludlam
 */
interface IEntity {

    /**
     * View supportsInterface - Checks support for given Interface Signature
     * @param interfaceSig = 4 byte Interface Signature
     * @return bool interface compliance status
     */
    function supportsInterface(bytes4 interfaceSig) external view returns (bool);

    /**
     * View ownerOf - Check owner of given token.
     * @param tokenId = token's id
     * @return owner of token
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    /**
     * Transaction approve - Give token control approval to account.
     * @param to = account address to give approval. Can't be address zero or owner.
     * @param tokenId = token approval is given for.
     * @dev caller must be: owner or owner operator.
     */
    function approve(address to, uint256 tokenId) external;
    
    /**
     * View getApproved - Check token approval account value.
     * @param tokenId = token approval to check on.
     * @return approved account address for token.
     */
    function getApproved(uint256 tokenId) external view returns (address approved);
    
    /**
     * Transaction setApprovalForAll - Set account-wide token operator.
     * @param operator = Account to give approval for operator power.
     * @param approved = Toggle approved operator power on or off.
     */
    function setApprovalForAll(address operator, bool approved) external;
    
    /**
     * View isApprovedForAll - Check account for approved operator power.
     * @param owner = Token owner.
     * @param operator = Owner account operator.
     * @return bool operator status
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    
    /**
     * Transaction transferFrom - Transfer token from account to account.
     * @param from = Account transfering token ownership.
     * @param to = Account recieving token ownership.
     * @param tokenId = Token being transfered.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;
    
    /**
     * Transaction safeTransferFrom - Safely transfer token from account to account.
     * @param from = Account transfering token ownership.
     * @param to = Account recieving token ownership.
     * @param tokenId = Token being transfered.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    
    /**
     * Transaction safeTransferFrom - Safely transfer token from account to 
     * account, with data.
     * @param from = Account transfering token ownership.
     * @param to = Account recieving token ownership.
     * @param tokenId = Token being transfered.
     * @param data = bytes included
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
    /**
     * Event Transfer - Fired when tokens transfered from one account to another.
     * @return from = Account transfering token ownership.
     * @return to = Account recieving token ownership.
     * @return tokenId = Token being transfered.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    
    /**
     * Event Approval - Fired when token approval is given.
     * @return owner = Token owner giving approval.
     * @return approved = Account given approval for token.
     * @return tokenId = Token approval is given for.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    
    /**
     * Event ApprovalForAll - Fired when owner's operator status changes
     * @return owner = Token owner.
     * @return operator = Operator account for owner.
     * @return approved = Boolean operator status.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
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
        uint256 indexed entity
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
        string name
    );
}