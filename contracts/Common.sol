pragma solidity ^0.4.23;

contract Ownable {

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

contract Vault is Ownable {

    function () public payable {

    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw(uint amount) public onlyOwner {
        require(address(this).balance >= amount);
        owner.transfer(amount);
    }

    function withdrawAll() public onlyOwner {
        withdraw(address(this).balance);
    }
}

contract CappedVault is Vault {

    uint public limit;
    uint withdrawn = 0;

    constructor() public {
        //hardcoded here because can't think of a reason of reset this limit.
        limit = 200000000 trx;
    }

    function () public payable {
        require(total() + msg.value <= limit);
    }

    function total() public view returns(uint) {
        return getBalance() + withdrawn;
    }

    function withdraw(uint amount) public onlyOwner {
        require(address(this).balance >= amount);
        owner.transfer(amount);
        withdrawn += amount;
    }

}

contract Governable {

    event Pause();
    event Unpause();

    address public governor;
    bool public paused = false;

    constructor() public {
        governor = msg.sender;
    }

    function setGovernor(address _gov) public onlyGovernor {
        governor = _gov;
    }

    modifier onlyGovernor {
        require(msg.sender == governor);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyGovernor whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyGovernor whenPaused public {
        paused = false;
        emit Unpause();
    }

}

contract Pausable is Ownable {

    event Pause();
    event Unpause();

    bool public paused = false;


    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract CardBase is Governable {


    struct Card {
        // the battle stats, such as atk, hp, cost etc..
        uint16 statsa;
        // a random property to determine visual effects only.
        uint16 cosmetica;
    }

    function getCard(uint id) public view returns (uint16 statsa, uint16 cosmetica) {
        Card memory card = cards[id];
        return (card.statsa, card.cosmetica);
    }

    Card[] public cards;

}

contract CardData is CardBase {

    event NewStatsaCard(
        uint16 id, uint8 season, uint8 style,
        Rarity rarity, uint8 mana, uint8 attack,
        uint8 health, uint8 cardType, uint8 kword, bool packable
    );

    struct Limit {
        uint64 limit;
        bool exists;
    }

    // limits for masterpiece cards
    mapping(uint16 => Limit) public limits;

    // can only set once
    function setLimit(uint16 id, uint64 limit) public onlyGovernor {
        Limit memory l = limits[id];
        require(!l.exists);
        limits[id] = Limit({
            limit: limit,
            exists: true
            });
    }

    function getLimit(uint16 id) public view returns (uint64 limit, bool set) {
        Limit memory l = limits[id];
        return (l.limit, l.exists);
    }

    mapping(uint8 => bool) public seasonTradable;
    mapping(uint8 => bool) public seasonTradabilityLocked;
    uint8 public currentSeason;

    function makeTradeable(uint8 season) public onlyGovernor {
        seasonTradable[season] = true;
    }

    function makeUntradable(uint8 season) public onlyGovernor {
        require(!seasonTradabilityLocked[season]);
        seasonTradable[season] = false;
    }

    function makePermanantlyTradable(uint8 season) public onlyGovernor {
        require(seasonTradable[season]);
        seasonTradabilityLocked[season] = true;
    }

    function isTradable(uint16 statsa) public view returns (bool) {
        return seasonTradable[statsas[statsa].season];
    }

    function nextSeason() public onlyGovernor {
        //Seasons shouldn't go to 0 if there is more than the uint8 should hold, the governor should know this ¯\_(ツ)_/¯ -M
        require(currentSeason <= 255);

        currentSeason++;
        masterpiece.length = 0;
        legendary.length = 0;
        epic.length = 0;
        rare.length = 0;
        common.length = 0;
    }

    enum Rarity {
        Common,
        Rare,
        Epic,
        Legendary,
        Masterpiece
    }

    uint8 constant SPELL = 1;
    uint8 constant MINION = 2;
    uint8 constant WEAPON = 3;
    uint8 constant HERO = 4;

    struct StatsaCard {
        bool exists;
        uint8 style;
        uint8 season;
        uint8 cardType;
        Rarity rarity;
        uint8 mana;
        uint8 attack;
        uint8 health;
        uint8 kword;
    }

    uint16 public statsaCount;

    mapping(uint16 => StatsaCard) statsas;

    uint16[] public masterpiece;
    uint16[] public legendary;
    uint16[] public epic;
    uint16[] public rare;
    uint16[] public common;

    function addStatsas(
        uint16[] externalIDs, uint8[] styles, Rarity[] rarities, uint8[] manas, uint8[] attacks, uint8[] healths, uint8[] cardTypes, uint8[] kwords, bool[] packable
    ) public onlyGovernor returns(uint16) {

        for (uint i = 0; i < externalIDs.length; i++) {

            StatsaCard memory card = StatsaCard({
                exists: true,
                style: styles[i],
                season: currentSeason,
                cardType: cardTypes[i],
                rarity: rarities[i],
                mana: manas[i],
                attack: attacks[i],
                health: healths[i],
                kword: kwords[i]
                });

            _addStatsa(externalIDs[i], card, packable[i]);
        }

    }

    function addStatsa(
        uint16 externalID, uint8 style, Rarity rarity, uint8 mana, uint8 attack, uint8 health, uint8 cardType, uint8 kword, bool packable
    ) public onlyGovernor returns(uint16) {
        StatsaCard memory card = StatsaCard({
            exists: true,
            style: style,
            season: currentSeason,
            cardType: cardType,
            rarity: rarity,
            mana: mana,
            attack: attack,
            health: health,
            kword: kword
            });

        _addStatsa(externalID, card, packable);
    }

    function addWeapon(
        uint16 externalID, uint8 style, Rarity rarity, uint8 mana, uint8 attack, uint8 durability, bool packable
    ) public onlyGovernor returns(uint16) {

        StatsaCard memory card = StatsaCard({
            exists: true,
            style: style,
            season: currentSeason,
            cardType: WEAPON,
            rarity: rarity,
            mana: mana,
            attack: attack,
            health: durability,
            kword: 0
            });

        _addStatsa(externalID, card, packable);
    }

    function addSpell(uint16 externalID, uint8 style, Rarity rarity, uint8 mana, bool packable) public onlyGovernor returns(uint16) {

        StatsaCard memory card = StatsaCard({
            exists: true,
            style: style,
            season: currentSeason,
            cardType: SPELL,
            rarity: rarity,
            mana: mana,
            attack: 0,
            health: 0,
            kword: 0
            });

        _addStatsa(externalID, card, packable);
    }

    function addMinion(
        uint16 externalID, uint8 style, Rarity rarity, uint8 mana, uint8 attack, uint8 health, uint8 kword, bool packable
    ) public onlyGovernor returns(uint16) {

        StatsaCard memory card = StatsaCard({
            exists: true,
            style: style,
            season: currentSeason,
            cardType: MINION,
            rarity: rarity,
            mana: mana,
            attack: attack,
            health: health,
            kword: kword
            });

        _addStatsa(externalID, card, packable);
    }

    function _addStatsa(uint16 externalID, StatsaCard memory card, bool packable) internal {

        require(!statsas[externalID].exists);

        card.exists = true;

        statsas[externalID] = card;

        statsaCount++;

        emit NewStatsaCard(
            externalID, currentSeason, card.style,
            card.rarity, card.mana, card.attack,
            card.health, card.cardType, card.kword, packable
        );

        if (packable) {
            Rarity rarity = card.rarity;
            if (rarity == Rarity.Common) {
                common.push(externalID);
            } else if (rarity == Rarity.Rare) {
                rare.push(externalID);
            } else if (rarity == Rarity.Epic) {
                epic.push(externalID);
            } else if (rarity == Rarity.Legendary) {
                legendary.push(externalID);
            } else if (rarity == Rarity.Masterpiece) {
                masterpiece.push(externalID);
            } else {
                require(false);
            }
        }
    }

    function getStatsa(uint16 id) public view returns(
        bool exists, uint8 style, uint8 season, uint8 cardType, Rarity rarity, uint8 mana, uint8 attack, uint8 health, uint8 kword
    ) {
        StatsaCard memory statsa = statsas[id];
        return (
        statsa.exists,
        statsa.style,
        statsa.season,
        statsa.cardType,
        statsa.rarity,
        statsa.mana,
        statsa.attack,
        statsa.health,
        statsa.kword
        );
    }

    function getRandomCard(Rarity rarity, uint16 random) public view returns (uint16) {
        // modulo bias is fine - creates rarity tiers etc
        // will obviously revert is there are no cards of that type: this is expected - should never happen
        if (rarity == Rarity.Common) {
            return common[random % common.length];
        } else if (rarity == Rarity.Rare) {
            return rare[random % rare.length];
        } else if (rarity == Rarity.Epic) {
            return epic[random % epic.length];
        } else if (rarity == Rarity.Legendary) {
            return legendary[random % legendary.length];
        } else if (rarity == Rarity.Masterpiece) {
            // make sure a masterpiece is available
            uint16 id;
            uint64 limit;
            bool set;
            for (uint i = 0; i < masterpiece.length; i++) {
                id = masterpiece[(random + i) % masterpiece.length];
                (limit, set) = getLimit(id);
                if (set && limit > 0){
                    return id;
                }
            }
            // if not, they get a legendary :(
            return legendary[random % legendary.length];
        }
        require(false);
        return 0;
    }

    // cannot adjust tradable cards
    // immutable: season, rarity
    function replaceStatsa(
        uint16 index, uint8 style, uint8 cardType, uint8 mana, uint8 attack, uint8 health, uint8 kword
    ) public onlyGovernor {
        StatsaCard memory pc = statsas[index];
        require(!seasonTradable[pc.season]);
        statsas[index] = StatsaCard({
            exists: true,
            style: style,
            season: pc.season,
            cardType: cardType,
            rarity: pc.rarity,
            mana: mana,
            attack: attack,
            health: health,
            kword: kword
            });
    }

}

interface ERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);
}

interface ERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() public view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs    owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public payable;
    function transfer(address _to, uint256 _tokenId) public payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) public payable;
    function approve(address _to, uint256 _tokenId) public payable;
    function setApprovalForAll(address _to, bool _approved) public;
    function getApproved(uint256 _tokenId) public view returns (address);
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract NFT is ERC721, ERC165, ERC721Metadata, ERC721Enumerable {}

contract CardOwnership is NFT, CardData {

    mapping(uint => address) owners;
    mapping(uint => address) approved;
    mapping(address => mapping(address => bool)) operators;

    // save space, limits to 2^40 tokens
    mapping(address => uint40[]) public ownedTokens;

    mapping(uint => string) uris;

    // same reason as ownedTokens
    uint24[] indices;

    uint public burnCount;


    function name() public view returns (string) {
        return "Renaissance";
    }


    function symbol() public view returns (string) {
        return "RNS";
    }


    function totalSupply() public view returns (uint) {
        return cards.length - burnCount;
    }


    function transfer(address to, uint id) public payable {
        require(owns(msg.sender, id));
        require(isTradable(cards[id].statsa));
        require(to != address(0));
        _transfer(msg.sender, to, id);
    }


    function _transfer(address from, address to, uint id) internal {
        approved[id] = address(0);
        owners[id] = to;
        _addToken(to, id);
        _removeToken(from, id);
        emit Transfer(from, to, id);
    }


    function _create(address to, uint id) internal {
        owners[id] = to;
        _addToken(to, id);
        emit Transfer(address(0), to, id);
    }


    function transferAll(address to, uint[] ids) public payable {
        for (uint i = 0; i < ids.length; i++) {
            transfer(to, ids[i]);
        }
    }


    function ownsAll(address proposed, uint[] ids) public view returns (bool) {
        for (uint i = 0; i < ids.length; i++) {
            if (!owns(proposed, ids[i])) {
                return false;
            }
        }
        return true;
    }


    function owns(address proposed, uint id) public view returns (bool) {
        return ownerOf(id) == proposed;
    }


    function ownerOf(uint id) public view returns (address) {
        return owners[id];
    }


    function burn(uint id) public {
        require(owns(msg.sender, id));
        burnCount++;
        _transfer(msg.sender, address(0), id);
    }

    function burnAll(uint[] ids) public {
        for (uint i = 0; i < ids.length; i++){
            burn(ids[i]);
        }
    }

    /**
    * @param to : the address to approve for transfer
    * @param id : the index of the card to be approved
    */
    function approve(address to, uint id) public payable {
        require(owns(msg.sender, id));
        require(isTradable(cards[id].statsa));
        approved[id] = to;
        emit Approval(msg.sender, to, id);
    }

    /**
    * @param to : the address to approve for transfer
    * @param ids : the indices of the cards to be approved
    */
    function approveAll(address to, uint[] ids) public payable {
        for (uint i = 0; i < ids.length; i++) {
            approve(to, ids[i]);
        }
    }

    /**
    * @param id : the index of the token to check
    * @return the address approved to transfer this token
    */
    function getApproved(uint id) public view returns(address) {
        return approved[id];
    }

    /**
    * @param owner : the address to check
    * @return the number of tokens controlled by owner
    */
    function balanceOf(address owner) public view returns (uint) {
        return ownedTokens[owner].length;
    }

    /**
    * @param id : the index of the proposed token
    * @return whether the token is owned by a non-zero address
    */
    function exists(uint id) public view returns (bool) {
        return owners[id] != address(0);
    }

    /**
    * @param to : the address to which the token should be transferred
    * @param id : the index of the token to transfer
    */
    function transferFrom(address from, address to, uint id) public payable {

        require(to != address(0));
        require(to != address(this));

        // TODO: why is this necessary
        // if you're approved, why does it matter where it comes from?
        require(ownerOf(id) == from);

        require(isSenderApprovedFor(id));

        require(isTradable(cards[id].statsa));

        _transfer(ownerOf(id), to, id);
    }

    /**
    * @param to : the address to which the tokens should be transferred
    * @param ids : the indices of the tokens to transfer
    */
    function transferAllFrom(address to, uint[] ids) public payable {
        for (uint i = 0; i < ids.length; i++) {
            transferFrom(address(0), to, ids[i]);
        }
    }

    /**
     * @return the number of cards which have been burned
     */
    function getBurnCount() public view returns (uint) {
        return burnCount;
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operators[owner][operator];
    }

    function setApprovalForAll(address to, bool toApprove) public {
        require(to != msg.sender);
        operators[msg.sender][to] = toApprove;
        emit ApprovalForAll(msg.sender, to, toApprove);
    }

    bytes4 constant magic = bytes4(keccak256("onERC721Received(address,uint256,bytes)"));

    function safeTransferFrom(address from, address to, uint id, bytes data) public payable {
        require(to != address(0));
        transferFrom(from, to, id);
        if (_isContract(to)) {
            bytes4 response = ERC721TokenReceiver(to).onERC721Received.gas(50000)(from, id, data);
            require(response == magic);
        }
    }

    function safeTransferFrom(address from, address to, uint id) public payable {
        safeTransferFrom(from, to, id, "");
    }

    function _addToken(address to, uint id) private {
        uint pos = ownedTokens[to].push(uint40(id)) - 1;
        indices.push(uint24(pos));
    }

    function _removeToken(address from, uint id) public payable {
        uint24 index = indices[id];
        uint lastIndex = ownedTokens[from].length - 1;
        uint40 lastId = ownedTokens[from][lastIndex];

        ownedTokens[from][index] = lastId;
        ownedTokens[from][lastIndex] = 0;
        ownedTokens[from].length--;
    }

    function isSenderApprovedFor(uint256 id) internal view returns (bool) {
        return owns(msg.sender, id) || getApproved(id) == msg.sender || isApprovedForAll(ownerOf(id), msg.sender);
    }

    function _isContract(address test) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(test)
        }
        return (size > 0);
    }

    function tokenURI(uint id) public view returns (string) {
        return uris[id];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 _tokenId){
        return ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) external view returns (uint256){
        return index;
    }

    function supportsInterface(bytes4 interfaceID) public view returns (bool) {
        return (
        interfaceID == this.supportsInterface.selector || // ERC165
        interfaceID == 0x5b5e139f || // ERC721Metadata
        interfaceID == 0x6466353c || // ERC-721 on 3/7/2018
        interfaceID == 0x780e9d63
        ); // ERC721Enumerable
    }

    function implementsERC721() external pure returns (bool) {
        return true;
    }

    function getOwnedTokens(address user) public view returns (uint40[]) {
        return ownedTokens[user];
    }


}

/// @dev Note: the ERC-165 identifier for this interface is 0xf0b9e5ba
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. This function MUST use 50,000 gas or less. Return of other
    ///  than the magic value MUST result in the transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _from The sending address
    /// @param _tokenId The NFT identifier which is being transfered
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}



contract CardIntegration is CardOwnership {

    CardPack[] packs;

    event CardCreated(uint indexed id, uint16 statsa, uint16 cosmetica, address owner);

    function addPack(CardPack approved) public onlyGovernor {
        packs.push(approved);
    }

    modifier onlyApprovedPacks {
        require(_isApprovedPack());
        _;
    }

    function _isApprovedPack() private view returns (bool) {
        for (uint i = 0; i < packs.length; i++) {
            if (msg.sender == address(packs[i])) {
                return true;
            }
        }
        return false;
    }

    function createCard(address owner, uint16 statsa, uint16 cosmetica) public whenNotPaused onlyApprovedPacks returns (uint) {
        StatsaCard memory card = statsas[statsa];
        require(card.season == currentSeason);
        if (card.rarity == Rarity.Masterpiece) {
            uint64 limit;
            bool exists;
            (limit, exists) = getLimit(statsa);
            require(!exists || limit > 0);
            limits[statsa].limit--;
        }
        return _createCard(owner, statsa, cosmetica);
    }

    function _createCard(address owner, uint16 statsa, uint16 cosmetica) internal returns (uint) {
        Card memory card = Card({
            statsa: statsa,
            cosmetica: cosmetica
            });

        uint id = cards.push(card) - 1;

        _create(owner, id);

        emit CardCreated(id, statsa, cosmetica, owner);

        return id;
    }
}

contract CardPack {

    CardIntegration public integration;
    uint public creationBlock;

    constructor(CardIntegration _integration) public {
        integration = _integration;
        creationBlock = block.number;
    }

    event Referral(address indexed referrer, uint value, address purchaser);

    /**
    * purchase 'count' of this type of pack
    */
    function purchase(uint16 packCount, address referrer) public payable;

    // store cosmetica and shine as one number to save users gas
    function _getCosmetica(uint16 randOne, uint16 randTwo) internal pure returns (uint16) {
        if (randOne >= 998) {
            return 3000 + randTwo;
        } else if (randOne >= 988) {
            return 2000 + randTwo;
        } else if (randOne >= 938) {
            return 1000 + randTwo;
        } else {
            return randTwo;
        }
    }

}



contract PresalePack is CardPack, Pausable {

    CappedVault public vault;

    Purchase[] purchases;

    struct Purchase {
        uint16 current;
        uint16 count;
        address user;
        uint randomness;
        uint64 commit;
    }

    event PacksPurchased(uint indexed id, address indexed user, uint16 count);
    event PackOpened(uint indexed id, uint16 startIndex, address indexed user, uint[] cardIDs);
    event RandomnessReceived(uint indexed id, address indexed user, uint16 count, uint randomness);

    constructor(CardIntegration integration, CappedVault _vault) public  CardPack(integration) {
        vault = _vault;
    }

    function basePrice() public returns (uint);
    function getCardDetails(uint16 packIndex, uint8 cardIndex, uint result) public view returns (uint16 statsa, uint16 cosmetica);

    function packSize() public view returns (uint8) {
        return 5;
    }

    function packsPerClaim() public view returns (uint16) {
        return 15;
    }

    // start in bytes, length in bytes
    function extract(uint num, uint length, uint start) internal pure returns (uint) {
        return (((1 << (length * 8)) - 1) & (num >> ((start * 8) - 1)));
    }

    uint public purchaseCount;
    uint public totalCount;

    function purchase(uint16 packCount, address referrer) whenNotPaused public payable {

        require(packCount > 0);
        require(referrer != msg.sender);

        uint price = calculatePrice(basePrice(), packCount);

        require(msg.value >= price);

        Purchase memory p = Purchase({
            user: msg.sender,
            count: packCount,
            commit: uint64(block.number),
            randomness: 0,
            current: 0
            });

        uint id = purchases.push(p) - 1;

        emit PacksPurchased(id, msg.sender, packCount);

        if (referrer != address(0)) {
            uint commission = price / 10;
            referrer.transfer(commission);
            price -= commission;
            emit Referral(referrer, commission, msg.sender);
        }

        address(vault).transfer(price);
    }

    // to determine rand seed
    // called after the block that card pack is bought. But not too far.(within next 256 blocks)
    function randomize(uint id) public {

        Purchase storage p = purchases[id];

        require(p.randomness == 0);

        bytes32 bhash = blockhash(p.commit);

        uint random = uint(keccak256(abi.encodePacked(totalCount, bhash)));

        totalCount += p.count;

        if (uint(bhash) == 0) {
            // set to 1 rather than 0 to avoid calling claim before randomness
            p.randomness = 1;
        } else {
            p.randomness = random;
        }

        emit RandomnessReceived(id, p.user, p.count, p.randomness);
    }


    // the card actually goes to the owner (not before, so to save energy)
    function claim(uint id) public {

        Purchase storage p = purchases[id];

        require(canClaim);

        uint16 statsa;
        uint16 cosmetica;
        uint16 count = p.count;
        uint result = p.randomness;
        uint8 size = packSize();

        address user = p.user;
        uint16 current = p.current;

        require(result != 0); // have to wait for the randomize
        require(count > 0);

        uint[] memory ids = new uint[](size);

        uint16 end = current + packsPerClaim() > count ? count : current + packsPerClaim();

        require(end > current);

        for (uint16 i = current; i < end; i++) {
            for (uint8 j = 0; j < size; j++) {
                (statsa, cosmetica) = getCardDetails(i, j, result);
                ids[j] = integration.createCard(user, statsa, cosmetica);
            }
            emit PackOpened(id, (i * size), user, ids);
        }
        p.current += (end - current);
    }

    // can view before claim, so to save energy
    function predictPacks(uint id) external view returns (uint16[] statsas, uint16[] purities) {

        Purchase memory p = purchases[id];

        uint16 statsa;
        uint16 cosmetica;
        uint16 count = p.count;
        uint result = p.randomness;
        uint8 size = packSize();

        purities = new uint16[](size * count);
        statsas = new uint16[](size * count);

        for (uint16 i = 0; i < count; i++) {
            for (uint8 j = 0; j < size; j++) {
                (statsa, cosmetica) = getCardDetails(i, j, result);
                purities[(i * size) + j] = cosmetica;
                statsas[(i * size) + j] = statsa;
            }
        }
        return (statsas, purities);
    }

    // price is lower when it just came out. A discount for early purchases.
    function calculatePrice(uint base, uint16 packCount) public view returns (uint) {
        uint difference = block.number - creationBlock;
        uint numDays = difference / 28800;
        if (20 > numDays) {
            return (base - (((20 - numDays) * base) / 100)) * packCount;
        }
        return base * packCount;
    }

    function _getCommonPlusRarity(uint32 rand) internal pure returns (CardData.Rarity) {
        if (rand == 999999) {
            return CardData.Rarity.Masterpiece;
        } else if (rand >= 998345) {
            return CardData.Rarity.Legendary;
        } else if (rand >= 986765) {
            return CardData.Rarity.Epic;
        } else if (rand >= 924890) {
            return CardData.Rarity.Rare;
        } else {
            return CardData.Rarity.Common;
        }
    }

    function _getRarePlusRarity(uint32 rand) internal pure returns (CardData.Rarity) {
        if (rand == 999999) {
            return CardData.Rarity.Masterpiece;
        } else if (rand >= 981615) {
            return CardData.Rarity.Legendary;
        } else if (rand >= 852940) {
            return CardData.Rarity.Epic;
        } else {
            return CardData.Rarity.Rare;
        }
    }

    function _getEpicPlusRarity(uint32 rand) internal pure returns (CardData.Rarity) {
        if (rand == 999999) {
            return CardData.Rarity.Masterpiece;
        } else if (rand >= 981615) {
            return CardData.Rarity.Legendary;
        } else {
            return CardData.Rarity.Epic;
        }
    }

    function _getLegendaryPlusRarity(uint32 rand) internal pure returns (CardData.Rarity) {
        if (rand == 999999) {
            return CardData.Rarity.Masterpiece;
        } else {
            return CardData.Rarity.Legendary;
        }
    }

    bool public canClaim = true;

    function setCanClaim(bool _claim) public onlyOwner {
        canClaim = _claim;
    }

    function getComponents(
        uint16 i, uint8 j, uint rand
    ) internal returns (
        uint random, uint32 rarityRandom, uint16 cosmeticaOne, uint16 cosmeticaTwo, uint16 statsaRandom
    ) {
        random = uint(keccak256(abi.encodePacked(i, rand, j)));
        rarityRandom = uint32(extract(random, 4, 10) % 1000000);
        cosmeticaOne = uint16(extract(random, 2, 4) % 1000);
        cosmeticaTwo = uint16(extract(random, 2, 6) % 1000);
        statsaRandom = uint16(extract(random, 2, 8) % (2**16-1));
        return (random, rarityRandom, cosmeticaOne, cosmeticaTwo, statsaRandom);
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }

}