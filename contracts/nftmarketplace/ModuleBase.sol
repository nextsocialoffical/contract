pragma solidity ^0.6.12;;

import "./Game.sol";

interface IGameInstToken {

    function transferFrom(
      address _from,
      address _to,
      uint256 _value
    ) external returns (bool success);

    function balanceOf(
      address _owner
    ) external returns (uint256);

    function allowance(
      address _owner,
      address _spender
    ) external returns (uint256);

}

contract Trade {

  using SafeMath for uint256;
  
  ILens public CONTRACT;

  
  address private _manager;
  address private _burnAddress = 0x000000000000000000000000000000000000dEaD;
  
  struct Wood {
        bool forSell;
        uint256 price;
        uint256 burnPercentage;
  }

  event Purchase(
        address indexed _from,
        address indexed _to,
        uint256 indexed _id,
        uint256 _value
  );

  event Listing(
        address indexed _owner,
        uint256 indexed _id,
        uint256 _value,
        uint256 _burnPercentage
  );
  
  constructor(NextSocial _game, address _seedToken) public {
    game = _game;
    SEED_CONTRACT = ILens(_seedToken);
    _manager = game.getOwner();
  }
  
  /** @dev List NextSocial Forest NFT for sell at specific price 
     *@param _id unsigned integer defines tokenID to list for sell
     *@param _price unsigned integer defines sell price in SEED for the tokenID 
     */
  function listNft(uint256 _id, uint256 _price, uint256 _burnPercent) public {
    
    address _owner = game.ownerOf(_id);
    address _approved = game.getApproved(_id);
     
    require(
      address(this) == _approved,
      " NextSocial: Contract is not approved to manage token of this ID "
    );

    require(
      msg.sender == _owner,
      " NextSocial: Only owner of token can list the token for sell "
    );

    uint256 _burnP = (msg.sender == _manager)?_burnPercent:0;
    
    nftSaleList[_id] = Wood(true, _price, _burnP);

    emit Listing(_owner, _id, _price, _burnP);

  }
  
  /** @dev Buy NextSocial Forest NFT for listed price 
     *@param _id unsigned integer defines tokenID to buy
     *@param _value unsigned integer defines value of SEED tokens to buy NFT 
     */
  function buygame(uint256 _id, uint256 _value) public {
     
     address _approved = game.getApproved(_id);
     
     require(
      address(this) == _approved,
      " NextSocial: Contract is not approved to manage token of this ID "
      );
     
     require(
      gameList[_id].forSell,
      " NextSocial: Token of this ID is not for sell "
      );
     
     require(
      gameList[_id].price <= _value,
      " NextSocial: Provided value is less than listed price "
      );

     require(
      SEED_CONTRACT.balanceOf(msg.sender) >= _value,
      " SEED : Buyer doesn't have enough balance to purchase token "
     );

     require(
      SEED_CONTRACT.allowance(msg.sender, address(this)) >= _value,
      " SEED :  Contract is not approved to spend tokens of user "
     );
     
     address _owner = game.ownerOf(_id);

        if(gameList[_id].burnPercentage == 0){
          
          SEED_CONTRACT.transferFrom(msg.sender, _owner, _value);
        
        } else {

          uint256 _burnValue = _value.mul(gameList[_id].burnPercentage).div(100);
          uint256 _transferValue = _value.sub(_burnValue);
          SEED_CONTRACT.transferFrom(msg.sender, _burnAddress, _burnValue);
          SEED_CONTRACT.transferFrom(msg.sender, _owner, _transferValue);

        }
     
     game.transferFrom(_owner, msg.sender, _id);

     gameList[_id] = Wood(false, 0, 0);

     emit Purchase(_owner, msg.sender, _id, _value);
  
  }

}