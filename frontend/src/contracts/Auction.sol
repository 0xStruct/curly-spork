//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Auction is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private totalItems;

    address platformAddress;
    uint listingPrice = 0.02 ether;
    uint royaltyFee;
    mapping(uint => AuctionStruct) auctionedItem;
    mapping(uint => bool) auctionedItemExist;
    mapping(string => uint) existingURIs;
    mapping(uint => BidderStruct[]) biddersOf;

    constructor(uint _royaltyFee) {
        platformAddress = msg.sender;
        royaltyFee = _royaltyFee;
    }

    struct BidderStruct {
        address bidder;
        uint price;
        uint timestamp;
        bool refunded;
        bool won;
    }

    struct AuctionStruct {
        string name;
        string description;
        string image;
        uint domain;
        address seller;
        address owner;
        address winner;
        uint price;
        bool sold;
        bool live;
        bool biddable;
        uint bids;
        uint duration;
    }

    event AuctionItemCreated(
        uint indexed domain,
        address seller,
        address owner,
        uint price,
        bool sold
    );

    function getListingPrice() public view returns (uint) {
        return listingPrice;
    }

    function setListingPrice(uint _price) public {
        require(msg.sender == platformAddress, "Unauthorized entity");
        listingPrice = _price;
    }

    function changePrice(uint domain, uint price) public {
        require(
            auctionedItem[domain].owner == msg.sender,
            "Unauthorized entity"
        );
        require(
            getTimestamp(0, 0, 0, 0) > auctionedItem[domain].duration,
            "Auction still Live"
        );
        require(price > 0 ether, "Price must be greater than zero");

        auctionedItem[domain].price = price;
    }

    // function mintToken(string memory tokenURI) internal returns (bool) {
    //     totalItems.increment();
    //     uint domain = totalItems.current();

    //     _mint(msg.sender, domain);
    //     _setTokenURI(domain, tokenURI);

    //     return true;
    // }

    function createAuction(
        string memory name,
        string memory description,
        // string memory image,
        // string memory tokenURI,
        uint price
    ) public payable nonReentrant {
        require(price > 0 ether, "Sales price must be greater than 0 ethers.");
        require(
            msg.value >= listingPrice,
            "Price must be up to the listing price."
        );
        // require(mintToken(tokenURI), "Could not mint token");

        totalItems.increment();
        uint domain = totalItems.current();

        AuctionStruct memory item;
        item.domain = domain;
        item.name = name;
        item.description = description;
        // item.image = image;
        item.price = price;
        item.duration = getTimestamp(0, 0, 0, 0);
        item.seller = msg.sender;
        item.owner = msg.sender;

        auctionedItem[domain] = item;
        auctionedItemExist[domain] = true;

        payTo(platformAddress, listingPrice);

        emit AuctionItemCreated(domain, msg.sender, address(0), price, false);
    }

    function offerAuction(
        uint domain,
        bool biddable,
        uint sec,
        uint min,
        uint hour,
        uint day
    ) public {
        require(
            auctionedItem[domain].owner == msg.sender,
            "Unauthorized entity"
        );
        require(
            auctionedItem[domain].bids == 0,
            "Winner should claim prize first"
        );

        if (!auctionedItem[domain].live) {
            // setApprovalForAll(address(this), true);
            // IERC721(address(this)).transferFrom(
            //     msg.sender,
            //     address(this),
            //     domain
            // );
        }

        auctionedItem[domain].bids = 0;
        auctionedItem[domain].live = true;
        auctionedItem[domain].sold = false;
        auctionedItem[domain].biddable = biddable;
        auctionedItem[domain].duration = getTimestamp(sec, min, hour, day);
    }

    function placeBid(uint domain) public payable {
        require(
            msg.value >= auctionedItem[domain].price,
            "Insufficient Amount"
        );
        require(
            auctionedItem[domain].duration > getTimestamp(0, 0, 0, 0),
            "Auction not available"
        );
        require(auctionedItem[domain].biddable, "Auction only for bidding");

        BidderStruct memory bidder;
        bidder.bidder = msg.sender;
        bidder.price = msg.value;
        bidder.timestamp = getTimestamp(0, 0, 0, 0);

        biddersOf[domain].push(bidder);
        auctionedItem[domain].bids++;
        auctionedItem[domain].price = msg.value;
        auctionedItem[domain].winner = msg.sender;
    }

    function claimPrize(uint domain, uint bid) public {
        require(
            getTimestamp(0, 0, 0, 0) > auctionedItem[domain].duration,
            "Auction still Live"
        );
        require(
            auctionedItem[domain].winner == msg.sender,
            "You are not the winner"
        );

        biddersOf[domain][bid].won = true;
        uint price = auctionedItem[domain].price;
        address seller = auctionedItem[domain].seller;

        auctionedItem[domain].winner = address(0);
        auctionedItem[domain].live = false;
        auctionedItem[domain].sold = true;
        auctionedItem[domain].bids = 0;
        auctionedItem[domain].duration = getTimestamp(0, 0, 0, 0);

        uint royality = (price * royaltyFee) / 100;
        payTo(auctionedItem[domain].owner, (price - royality));
        payTo(seller, royality);
        // IERC721(address(this)).transferFrom(address(this), msg.sender, domain);
        auctionedItem[domain].owner = msg.sender;

        performRefund(domain);
    }

    function performRefund(uint domain) internal {
        for (uint i = 0; i < biddersOf[domain].length; i++) {
            if (biddersOf[domain][i].bidder != msg.sender) {
                biddersOf[domain][i].refunded = true;
                payTo(
                    biddersOf[domain][i].bidder,
                    biddersOf[domain][i].price
                );
            } else {
                biddersOf[domain][i].won = true;
            }
            biddersOf[domain][i].timestamp = getTimestamp(0, 0, 0, 0);
        }

        delete biddersOf[domain];
    }

    function buyAuctionedItem(uint domain) public payable nonReentrant {
        require(
            msg.value >= auctionedItem[domain].price,
            "Insufficient Amount"
        );
        require(
            auctionedItem[domain].duration > getTimestamp(0, 0, 0, 0),
            "Auction not available"
        );
        require(!auctionedItem[domain].biddable, "Auction only for purchase");

        address seller = auctionedItem[domain].seller;
        auctionedItem[domain].live = false;
        auctionedItem[domain].sold = true;
        auctionedItem[domain].bids = 0;
        auctionedItem[domain].duration = getTimestamp(0, 0, 0, 0);

        uint royality = (msg.value * royaltyFee) / 100;
        payTo(auctionedItem[domain].owner, (msg.value - royality));
        payTo(seller, royality);
        // IERC721(address(this)).transferFrom(
        //     address(this),
        //     msg.sender,
        //     auctionedItem[domain].domain
        // );

        auctionedItem[domain].owner = msg.sender;
    }

    function getAuction(uint domain) public view returns (AuctionStruct memory) {
        require(auctionedItemExist[domain], "Auctioned Item not found");
        return auctionedItem[domain];
    }

    function getAllAuctions()
        public
        view
        returns (AuctionStruct[] memory Auctions)
    {
        uint totalItemsCount = totalItems.current();
        Auctions = new AuctionStruct[](totalItemsCount);

        for (uint i = 0; i < totalItemsCount; i++) {
            Auctions[i] = auctionedItem[i + 1];
        }
    }

    function getUnsoldAuction()
        public
        view
        returns (AuctionStruct[] memory Auctions)
    {
        uint totalItemsCount = totalItems.current();
        uint totalSpace;
        for (uint i = 0; i < totalItemsCount; i++) {
            if (!auctionedItem[i + 1].sold) {
                totalSpace++;
            }
        }

        Auctions = new AuctionStruct[](totalSpace);

        uint index;
        for (uint i = 0; i < totalItemsCount; i++) {
            if (!auctionedItem[i + 1].sold) {
                Auctions[index] = auctionedItem[i + 1];
                index++;
            }
        }
    }

    function getMyAuctions()
        public
        view
        returns (AuctionStruct[] memory Auctions)
    {
        uint totalItemsCount = totalItems.current();
        uint totalSpace;
        for (uint i = 0; i < totalItemsCount; i++) {
            if (auctionedItem[i + 1].owner == msg.sender) {
                totalSpace++;
            }
        }

        Auctions = new AuctionStruct[](totalSpace);

        uint index;
        for (uint i = 0; i < totalItemsCount; i++) {
            if (auctionedItem[i + 1].owner == msg.sender) {
                Auctions[index] = auctionedItem[i + 1];
                index++;
            }
        }
    }

    function getSoldAuction()
        public
        view
        returns (AuctionStruct[] memory Auctions)
    {
        uint totalItemsCount = totalItems.current();
        uint totalSpace;
        for (uint i = 0; i < totalItemsCount; i++) {
            if (auctionedItem[i + 1].sold) {
                totalSpace++;
            }
        }

        Auctions = new AuctionStruct[](totalSpace);

        uint index;
        for (uint i = 0; i < totalItemsCount; i++) {
            if (auctionedItem[i + 1].sold) {
                Auctions[index] = auctionedItem[i + 1];
                index++;
            }
        }
    }

    function getLiveAuctions()
        public
        view
        returns (AuctionStruct[] memory Auctions)
    {
        uint totalItemsCount = totalItems.current();
        uint totalSpace;
        for (uint i = 0; i < totalItemsCount; i++) {
            if (auctionedItem[i + 1].duration > getTimestamp(0, 0, 0, 0)) {
                totalSpace++;
            }
        }

        Auctions = new AuctionStruct[](totalSpace);

        uint index;
        for (uint i = 0; i < totalItemsCount; i++) {
            if (auctionedItem[i + 1].duration > getTimestamp(0, 0, 0, 0)) {
                Auctions[index] = auctionedItem[i + 1];
                index++;
            }
        }
    }

    function getBidders(uint domain)
        public
        view
        returns (BidderStruct[] memory)
    {
        return biddersOf[domain];
    }

    function getTimestamp(
        uint sec,
        uint min,
        uint hour,
        uint day
    ) internal view returns (uint) {
        return
            block.timestamp +
            (1 seconds * sec) +
            (1 minutes * min) +
            (1 hours * hour) +
            (1 days * day);
    }

    function payTo(address to, uint amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success);
    }
}
