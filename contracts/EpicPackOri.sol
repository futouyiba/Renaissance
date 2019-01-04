pragma solidity ^0.4.23;
import "./Common.sol";

contract EpicPack is PresalePack {

    constructor(CardIntegration integration, CappedVault _vault) public payable PresalePack(integration, _vault) {

    }

    function basePrice() public returns (uint) {
        return 450 trx;
    }

    function getCardDetails(uint16 packIndex, uint8 cardIndex, uint result) public view returns (uint16 statsa, uint16 cosmetica) {
        uint random;
        uint32 rarityRandom;
        uint16 statsaRandom;
        uint16 cosmeticaOne;
        uint16 cosmeticaTwo;
        CardData.Rarity rarity;

        (random, rarityRandom, cosmeticaOne, cosmeticaTwo, statsaRandom) = getComponents(packIndex, cardIndex, result);

        if (cardIndex == 4) {
            rarity = _getEpicPlusRarity(rarityRandom);
        } else {
            rarity = _getCommonPlusRarity(rarityRandom);
        }

        cosmetica = _getCosmetica(cosmeticaOne, cosmeticaTwo);

        statsa = integration.getRandomCard(rarity, statsaRandom);

        return (statsa, cosmetica);
    }
}