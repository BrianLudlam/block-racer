pragma solidity ^0.5.8;

/**
 * @title ERC721 Standard Receiver Interface (Abstract)
 * @author Brian Ludlam
 */
contract IERC721Receiver {
    
    /**
     * View onERC721Received - ERC721 Receiver check function
     * @param operator = Account doing the transfer.
     * @param from = Account token is transfering from.
     * @param tokenId =  Token being transfered.
     * @param data = Data includedd with transfer.
     * @return bytes4 = Interface Signature to show standard ERC721 compliance.
     */
    function onERC721Received(
        address operator, 
        address from, 
        uint256 tokenId, 
        bytes memory data
    ) public returns (bytes4);
}