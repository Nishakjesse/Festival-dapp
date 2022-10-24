  // SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
  function transfer(address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Festival {

    uint internal programmesLength = 0;
    address internal cUsdTokenAddress = 0x686c626E48bfC5DC98a30a9992897766fed4Abd3;

    struct Programme {
        address payable owner;
        string url;
        string theme;
        string description;
        string location;
        uint price;
        uint sold;
    }

    mapping (uint => Programme) internal programmes;

    function writeProgramme(
        string memory _url,
        string memory _theme,
        string memory _description, 
        string memory _location, 
        uint _price
    ) public {
        uint _sold = 0;
        programmes[programmesLength] = Programme(
            payable(msg.sender),
            _url,
            _theme,
            _description,
            _location,
            _price,
            _sold
        );
        programmesLength++;
    }

    function readProgramme(uint _index) public view returns (
        address payable,
        string memory, 
        string memory, 
        string memory, 
        string memory, 
        uint, 
        uint
    ) {
        return (
            programmes[_index].owner,
            programmes[_index].url, 
            programmes[_index].theme, 
            programmes[_index].description, 
            programmes[_index].location, 
            programmes[_index].price,
            programmes[_index].sold
        );
    }

    function bookSlot(uint _index) public payable  {
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            programmes[_index].owner,
            programmes[_index].price
          ),
          "Transfer failed."
        );
        programmes[_index].sold++;
    }
    
    function getProgrammesLength() public view returns (uint) {
        return (programmesLength);
    }
}