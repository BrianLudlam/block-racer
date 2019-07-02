pragma solidity ^0.5.8;
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

/**
 * @title Contract ERC721 is standard IERC165, IERC721 implementation with
 * sequential-index token minting.
 * @author Brian Ludlam
 */
contract ERC721 is IERC165, IERC721 {
    
    /* ERC165 Standard Interface Signatures */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
 
    mapping(bytes4 => bool) private _supportedInterfaces;

    mapping (uint256 => address) private _owner;
    mapping (address => uint256) private _ownerTotal;
    mapping (uint256 => address) private _approval;
    mapping (address => mapping (address => bool)) private _operator;
    
    uint256 private _tokenIndex;

    constructor() public { 
        _supportedInterfaces[_INTERFACE_ID_ERC165] = true;
        _supportedInterfaces[_INTERFACE_ID_ERC721] = true;
    }
    
    /* ERC165 Standard Implementation */
    
    /**
     * @notice Checks support for given Interface Signature
     * @param interfaceSig = 4 byte Interface Signature
     * @return bool interface inclusion status
     */
    function supportsInterface(bytes4 interfaceSig) external view returns (bool) {
        return _supportedInterfaces[interfaceSig];
    }
    
    /* ERC721 Standard Implementation */
    
    /**
     * View ownerOf - Check owner of given token.
     * @param tokenId = token's id
     * @return owner of token
     */
    function ownerOf(uint256 tokenId) public view returns (address owner) {
        owner = _owner[tokenId];
    }
    
    /**
     * View balanceOf - Check owner's token balance.
     * @param owner = token owner.
     * @return token balance of owner, or global token count if owner = address zero.
     */
    function balanceOf(address owner) external view returns (uint256 balance) {
        balance = ((owner != address(0)) ? _ownerTotal[owner] : _tokenIndex);
    } 
    
    /**
     * Transaction approve - Give token approval to account.
     * @param to = account address to give approval. Can't be address zero or owner.
     * @param tokenId = token approval is given for.
     * @dev caller must be: owner or owner operator.
     * @dev Emits Approval event on success.
     */
    function approve(address to, uint256 tokenId) external {
        require(to != address(0) && to != _owner[tokenId]);
        require(msg.sender == _owner[tokenId] || _operator[_owner[tokenId]][msg.sender]);
        _approval[tokenId] = to;
        emit Approval(_owner[tokenId], to, tokenId);
    }
    
    /**
     * View getApproved - Check token approval account value.
     * @param tokenId = token approval to check on.
     * @return approved account address for token, or address zero if none.
     * @dev above-index tokenId and tokens without approval, will return 
     * address zero. Only tokens with valid approval address will return valid.
     */
    function getApproved(uint256 tokenId) external view returns (address approved) {
        approved = _approval[tokenId];
    }
    
    /**
     * Transaction setApprovalForAll - Set account-wide token operator.
     * @param operator = Account to give approval for operator power. Can't be
     * address zero, or sender.
     * @param approved = Toggle approved owner operator power on or off.
     * @dev Emits ApprovalForAll event on success.
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(operator != address(0) && operator != msg.sender);
        if (_operator[msg.sender][operator] != approved) {
            _operator[msg.sender][operator] = approved;
            emit ApprovalForAll(msg.sender, operator, approved);
        }
    }
    
    /**
     * View isApprovedForAll - Check account for approved operator power.
     * @param owner = Token owner.
     * @param operator = Owner account operator.
     * @return bool operator status
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operator[owner][operator];
    }
    
    /**
     * Transaction transferFrom - Transfer token from account to account.
     * @param from = Account transfering token ownership. Must be token owner.
     * @param to = Account recieving token ownership. Can't be same as from, or 
     * address zero. Sender must be: owner, owner operator, or have direct token approval.
     * @param tokenId = Token being transfered.
     * @dev clear token approvals and emit Transfer event on success.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(from == _owner[tokenId] && to != from && to != address(0));
        require (
            _owner[tokenId] == msg.sender || 
            _approval[tokenId] == msg.sender || 
            _operator[_owner[tokenId]][msg.sender]
        );
        //clear token approvals for new owner
        if (_approval[tokenId] != address(0)) _approval[tokenId] = address(0);
        _ownerTotal[from]--;
        _ownerTotal[to]++;
        _owner[tokenId] = to;
        emit Transfer(from, to, tokenId, now);
    }

     /**
     * Transaction safeTransferFrom - Safely transfer token from account to 
     * account, with data.
     * @dev Safely = Receiving account is either not contract or ERC721 compliant contract.
     * @param from = Account transfering token ownership.
     * @param to = Account recieving token ownership.
     * @param tokenId = Token being transfered.
     * @param data = data included wit transfer.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        require(checkOnERC721Received(from, to, tokenId, data));
    }
    
    /**
     * Transaction safeTransferFrom - Safely transfer token from account 
     * to account, without data.
     * @dev Safely = Receiving account is either not contract or ERC721 compliant contract.
     * @param from = Account transfering token ownership.
     * @param to = Account recieving token ownership.
     * @param tokenId = Token being transfered.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    /**
     * @notice Internal checkOnERC721Received - Check recieving account is either
     * not contract or ERC721 compliant contract by returning magic interface signature.
     * @param from = Account transfering token ownership.
     * @param to = Account recieving token ownership.
     * @param tokenId = Token being transfered.
     * @param data = data included wit transfer.
     */
    function checkOnERC721Received(
        address from, 
        address to, 
        uint256 tokenId, 
        bytes memory data
    ) internal returns (bool) {
        uint256 size;
        assembly { size := extcodesize(to) }
        if (size == 0) return true;//not a contract
        bytes4 sig = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data);
        return (sig == _ERC721_RECEIVED);//is ERC721 compliant contract.
    }
    
    /**
     * @notice Internal mintFor - Mint next-index token for owner.
     * @param owner = Token owner to be.
     * @return id = Token minted.
     * @dev Emits Transfer event from address zero.
     */
    function mintFor(address owner) internal returns (uint256 tokenId) {
        require (owner != address(0));
        tokenId = ++_tokenIndex;
        _owner[tokenId] = owner;
        _ownerTotal[owner]++;
        emit Transfer(address(0), owner, tokenId, now);
    }
}