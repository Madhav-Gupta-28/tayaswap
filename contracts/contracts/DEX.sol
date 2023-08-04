 // SPDX-License-Identifier: MIT
  pragma solidity ^0.8.18;

  import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

  contract TayaSwap is ERC20 {


    address public tayaTokenAddress;

      // Exchange is inheriting ERC20, becase our exchange would keep track of Crypto Dev LP tokens
      constructor(address _tayatoken) ERC20("Taya LP Token", "lpTAYA") {
          require(_tayatoken != address(0), "Token address passed is a null address");
          tayaTokenAddress = _tayatoken;
      }
        
      /**
        *  @dev Adds liquidity to the exchange.
    */
function addLiquidity(uint _amount) public payable returns (uint) {
    uint liquidity;
    uint ethBalance = address(this).balance;
    uint tayaTokenReserve = getTAYAReservebalance();
    ERC20 tayaToken = ERC20(tayaTokenAddress);
    /*
        If the reserve is empty, intake any user supplied value for
        `Ether` and `Crypto Dev` tokens because there is no ratio currently
    */
    if(tayaTokenReserve == 0) {
        tayaToken.transferFrom(msg.sender, address(this), _amount);
        liquidity = ethBalance;
        _mint(msg.sender, liquidity);
    } else {
      
        uint ethReserve =  ethBalance - msg.value;
        uint cryptoDevTokenAmount = (msg.value * tayaTokenReserve)/(ethReserve);
        require(_amount >= cryptoDevTokenAmount, "Amount of tokens sent is less than the minimum tokens required");
       
        tayaToken.transferFrom(msg.sender, address(this), cryptoDevTokenAmount);
    
        liquidity = (totalSupply() * msg.value)/ ethReserve;
        _mint(msg.sender, liquidity);
    }
     return liquidity;
}


/** 
  * @dev Returns the amount Eth/Crypto Dev tokens that would be returned to the user
  * in the swap
  */
  function removeLiquidity(uint _amount) public returns (uint , uint) {
      require(_amount > 0, "_amount should be greater than zero");
      uint ethReserve = address(this).balance;
      uint _totalSupply = totalSupply();
      uint ethAmount = (ethReserve * _amount)/ _totalSupply;
      // The amount of Crypto Dev token that would be sent back to the user is based
      // on a ratio
      // Ratio is -> (Crypto Dev sent back to the user) / (current Crypto Dev token reserve)
      // = (amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
      // Then by some maths -> (Crypto Dev sent back to the user)
      // = (current Crypto Dev token reserve * amount of LP tokens that user wants to withdraw) / (total supply of LP tokens)
      uint cryptoDevTokenAmount = (getTAYAReservebalance() * _amount)/ _totalSupply;
      // Burn the sent LP tokens from the user's wallet because they are already sent to
      // remove liquidity
      _burn(msg.sender, _amount);
      // Transfer `ethAmount` of Eth from user's wallet to the contract
      payable(msg.sender).transfer(ethAmount);
      // Transfer `cryptoDevTokenAmount` of Crypto Dev tokens from the user's wallet to the contract
      ERC20(tayaTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
      return (ethAmount, cryptoDevTokenAmount);
  }

    /**
* @dev Returns the amount Eth/Crypto Dev tokens that would be returned to the user
* in the swap
*/
function getAmountOfTokens(
    uint256 inputAmount,
    uint256 inputReserve,
    uint256 outputReserve
) public pure returns (uint256) {
    require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
    // We are charging a fee of `1%`
    // Input amount with fee = (input amount - (1*(input amount)/100)) = ((input amount)*99)/100
    uint256 inputAmountWithFee = inputAmount * 99;
    // Because we need to follow the concept of `XY = K` curve
    // We need to make sure (x + Δx) * (y - Δy) = x * y
    // So the final formula is Δy = (y * Δx) / (x + Δx)
    // Δy in our case is `tokens to be received`
    // Δx = ((input amount)*99)/100, x = inputReserve, y = outputReserve
    // So by putting the values in the formulae you can get the numerator and denominator
    uint256 numerator = inputAmountWithFee * outputReserve;
    uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
    return numerator / denominator;
}


/** 
* @dev Swaps Eth for CryptoDev Tokens
*/
function ethToTayaToken(uint _minTokens) public payable {
    uint256 tokenReserve = getTAYAReservebalance();
    // user has sent in the given call
    // so we need to subtract it to get the actual input reserve
    uint256 tokensBought = getAmountOfTokens(
        msg.value,
        address(this).balance - msg.value,
        tokenReserve
    );

    require(tokensBought >= _minTokens, "insufficient output amount");
    // Transfer the `Crypto Dev` tokens to the user
    ERC20(tayaTokenAddress).transfer(msg.sender, tokensBought);
}

/** 
* @dev Swaps CryptoDev Tokens for Eth
*/
function cryptoDevTokenToEth(uint _tokensSold, uint _minEth) public {
    uint256 tokenReserve = getTAYAReservebalance();
    // call the `getAmountOfTokens` to get the amount of Eth
    // that would be returned to the user after the swap
    uint256 ethBought = getAmountOfTokens(
        _tokensSold,
        tokenReserve,
        address(this).balance
    );
    require(ethBought >= _minEth, "insufficient output amount");
    // Transfer `Crypto Dev` tokens from the user's address to the contract
    ERC20(tayaTokenAddress).transferFrom(
        msg.sender,
        address(this),
        _tokensSold
    );
    // send the `ethBought` to the user from the contract
    payable(msg.sender).transfer(ethBought);
}


    /**
     * @notice Returns the ETH balance of this contract
     */
      function getETHReservebalance() public view returns(uint256) {
          return address(this).balance;
      }


      
    /**
     * @notice Returns the TAYA balance of this contract
     */
      function getTAYAReservebalance() public view returns(uint256) {
          return ERC20(tayaTokenAddress).balanceOf(address(this));
      }
  }