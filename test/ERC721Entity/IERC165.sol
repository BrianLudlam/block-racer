pragma solidity ^0.5.8;

/**
 * @title Standard ERC165 Interface
 * @author Brian Ludlam
 */
interface IERC165 {
    /**
     * View supportsInterface - Checks support for given Interface Signature
     * @param interfaceSig = 4 byte Interface Signature
     * @return bool interface compliance status
     */
    function supportsInterface(bytes4 interfaceSig) external view returns (bool);
}