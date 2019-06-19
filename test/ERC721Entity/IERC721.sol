pragma solidity ^0.5.8;

/**
 * @title ERC721 Standard Interface
 * @author Brian Ludlam
 */
interface IERC721 {
    
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
}