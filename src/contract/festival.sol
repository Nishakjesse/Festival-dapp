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

    uint internal programmesLength;
    uint private cancelRequestsLength;
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

    struct CancelRequest{
        uint programmeIndex;
        uint amount;
        address requester;
        bool fulfilled;
    }

    mapping (uint => Programme) private programmes;
    mapping (uint => mapping(address => uint)) private spotsBought;
    mapping (uint => CancelRequest) public cancelRequests;

    /**
        * @dev Allow users to add a programme to the marketplace
        * @notice Input data needs to contain only non-empty/valid values
     */
    function writeProgramme(
        string calldata _url,
        string calldata _theme,
        string calldata _description, 
        string calldata _location, 
        uint _price
    ) public {
        require(bytes(_url).length > 0,"Empty url");
        require(bytes(_theme).length > 0,"Empty theme");
        require(bytes(_description).length > 0,"Empty description");
        require(bytes(_location).length > 0,"Empty location");
        require(_price > 0,"Invalid price");
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

    /**
        * @dev allow users to book a slot/spot for a programme
        * @param quantity the number of slots/spots to book
        
     */
    function bookSlot(uint _index, uint quantity) public payable  {
        require(quantity > 0, "Quantity needs to be at least one");
        Programme storage currentProgramme = programmes[_index];
        require(currentProgramme.owner != msg.sender, "You can't buy your programme");
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            currentProgramme.owner,
            (currentProgramme.price * quantity)
          ),
          "Transfer failed."
        );
        spotsBought[_index][msg.sender] += quantity;
        uint newSoldAmount = currentProgramme.sold + quantity;
        currentProgramme.sold = newSoldAmount;
    }

    /**
        * @dev allow users to create a cancel request that would refund them for buying spots for a programme
        * @param quantity the amount of spots to refund
     */
    function cancelBooking(uint _index, uint quantity) public {
        uint userSpotsBought = spotsBought[_index][msg.sender]; 
        require(userSpotsBought > 0, "You haven't booked any spot for this programme");
        require(userSpotsBought >= quantity, "Invalid quantity selected");
        spotsBought[_index][msg.sender] -= quantity;
        cancelRequests[cancelRequestsLength] = CancelRequest(_index, userSpotsBought, msg.sender, false);
    }

    /**
        * @dev allow programmes's owners to refund a request
     */
    function fulfillCancelRequest(uint _requestIndex) public {
        CancelRequest storage currentRequest = cancelRequests[_requestIndex];
        require(!currentRequest.fulfilled, "Request has already been fulfilled");
        require(programmes[currentRequest.programmeIndex].owner == msg.sender, "Only owner of the programme can fulfill and refund a request");
        currentRequest.fulfilled = true;
        require(
          IERC20Token(cUsdTokenAddress).transferFrom(
            msg.sender,
            currentRequest.requester,
            (programmes[currentRequest.programmeIndex].price * currentRequest.amount)
          ),
          "Transfer failed."
        );
    }
    
    function getProgrammesLength() public view returns (uint) {
        return (programmesLength);
    }
}
