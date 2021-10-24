// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Base64 encode helper
import "./libraries/Base64.sol";

import "hardhat/console.sol";

contract PixiCats is ERC721 {
  // character attributes
  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint attackDamage;
  }
  
  // Boss attributes
  struct BigBoss {
  string name;
  string imageURI;
  uint hp;
  uint maxHp;
  uint attackDamage;
  }

  BigBoss public bigBoss;

  
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  
  // default data for characters
  CharacterAttributes[] defaultCharacters;
  
  // Create mapping from nft's tokenId
  mapping(uint256 => CharacterAttributes) public nftHolderAttributes;
  
  // Create mapping from address to NFTs tokenId. 
  // Helps store owner of NFT for reference.
  mapping(address => uint256) public nftHolders;
  
  // Events!
  event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
  event AttackComplete(uint newBossHp, uint newPlayerHp);

  // Data passed into contract when initializing characters
  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    uint[] memory characterHp,
    uint[] memory characterAttackDmg,
    string memory bossName,
    string memory bossImageURI,
    uint bossHp,
    uint bossAttackDamage
  )
    ERC721("Cats", "CAT")
  {
    // init boss
    bigBoss = BigBoss({
      name: bossName,
      imageURI: bossImageURI,
      hp: bossHp,
      maxHp: bossHp,
      attackDamage: bossAttackDamage
    });
    
    console.log("Done initializing boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);
    
    // loop through characters and save their values into contract
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name: characterNames[i],
        imageURI: characterImageURIs[i],
        hp: characterHp[i],
        maxHp: characterHp[i],
        attackDamage: characterAttackDmg[i]
      }));
      
      CharacterAttributes memory c = defaultCharacters[i];
      console.log("Done initializing %s w/ HP %s, img %s", c.name, c.hp, c.imageURI);
    }
    // increment tokenIds - first NFT has ID = 1
    _tokenIds.increment();
  }
  
  // Function for users to get their NFT based on characterId
  function mintCharacterNFT(uint _characterIndex) external {
    // Get current tokenId
    uint256 newItemId = _tokenIds.current();
    
    // Assign tokenId to caller's wallet address
    _safeMint(msg.sender, newItemId);
    
    // Map tokenId to character attributes.
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      hp: defaultCharacters[_characterIndex].hp,
      maxHp: defaultCharacters[_characterIndex].hp,
      attackDamage: defaultCharacters[_characterIndex].attackDamage
    });
    
    console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);
    
    // Way to show who own what NFT.
    nftHolders[msg.sender] = newItemId;
    
    // Increment tokenId for next person
    _tokenIds.increment();
    
    emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
  }
  
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

    string memory strHp = Strings.toString(charAttributes.hp);
    string memory strMaxHp = Strings.toString(charAttributes.maxHp);
    string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            charAttributes.name,
            ' -- NFT #: ',
            Strings.toString(_tokenId),
            '", "description": "This is an NFT that lets people play in the game PixiCats!", "image": "',
            charAttributes.imageURI,
            '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
            strAttackDamage,'} ]}'
          )
        )
      )
    );

    string memory output = string(
      abi.encodePacked("data:application/json;base64,", json)
    );
    
    return output;
  }
  
  function attackBoss() public {
    // Get the state of the player's NFT.
    uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
    CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
    console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
    console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);
    
    // Make sure the player has more than 0 HP.
    require (
      player.hp > 0,
      "Error: character must have HP to attack boss."
    );
    
    // Make sure the boss has more than 0 HP.
    require (
      bigBoss.hp > 0,
      "Error: boss must have HP to attack boss."
    );
    
    // Allow player to attack boss. Check for negatives because
    // uint doesn't handle negative values and int is a pain to work with.
    if (bigBoss.hp < player.attackDamage) {
      bigBoss.hp = 0;
    } else {
      bigBoss.hp = bigBoss.hp - player.attackDamage;
    }
    
    // Allow boss to attack player, also checking for negative value
    if (player.hp < bigBoss.attackDamage) {
      player.hp = 0;
    } else {
      player.hp = player.hp - bigBoss.attackDamage;
    }
    
    console.log("Boss attacked player. New player hp: %s\n", player.hp);
    
    emit AttackComplete(bigBoss.hp, player.hp);
  }
  
  function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
    // Get the tokenId of the user's character NFT
   uint256 userNftTokenId = nftHolders[msg.sender];
   
    // If the user has a tokenId in the map, return thier character.
    if (userNftTokenId > 0) {
      return nftHolderAttributes[userNftTokenId];
    }
    
    // Else, return an empty character.
    else {
      CharacterAttributes memory emptyStruct;
      return emptyStruct;
    }
  }
  
  // Get default characters for player to select from.
  function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
    return defaultCharacters;
  }
  
  function getBigBoss() public view returns (BigBoss memory) {
    return bigBoss;
  }
}