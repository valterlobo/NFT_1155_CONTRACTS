import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./MintNFT1155.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC1155Factory is ERC2771Context, Ownable {
    mapping(string => bool) public sessionTracker;
    address public trustedForwarder;
    address public operator;

    constructor(
        address _operator,
        address _forwarder
    ) ERC2771Context(_forwarder) {
        trustedForwarder = _forwarder;
        operator = _operator;
    }

    event CollectionCreation(
        address indexed collectionAddress,
        address indexed collector
    );

    mapping(address => mapping(string => address)) public collectionRecords;

    //This should be overriden in this contract since both context.sol and ERC2771Context.sol have the same function name and params.
    function _msgSender()
        internal
        view
        override(ERC2771Context, Context)
        returns (address sender)
    {
        sender = ERC2771Context._msgSender();
    }

    //This should be overriden in this contract since both context.sol and ERC2771Context.sol have the same function name and params.
    function _msgData()
        internal
        view
        virtual
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function createCollection(
        address collector,
        string calldata _session,
        string memory _name,
        string memory _sybmol
    ) external {
        require(
            !sessionTracker[_session],
            "Collection already deployed with the provided session ID"
        );
        require(
            collector != address(0),
            "Collector address should not be zero!"
        );
        MintNFT1155 collection = new MintNFT1155(
            _name,
            _sybmol,
            collector,
            trustedForwarder,
            address(this)
        );
        collectionRecords[collector][_session] = address(collection);
        sessionTracker[_session] = true;
        emit CollectionCreation(address(collection), collector);
    }

    function mintUnderCollection(
        address collection,
        string calldata _session,
        address to,
        string memory _uri,
        uint256 _amount
    ) external {
        if (
            _msgSender() == operator ||
            collectionRecords[_msgSender()][_session] == address(collection)
        ) {
            MintNFT1155(collection).mint(to, _uri, _amount);
        } else {
            revert("Not allowed to mint under this contract!");
        }
    }
}
