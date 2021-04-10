/*
 * Copyright © 2021 asi.finance. ALL RIGHTS RESERVED.
 */

pragma solidity ^0.6.12;

import "./libs/IBEP20.sol";
import './libs/IPancakePair.sol';
import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract BBOTSToken is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = 'AsiSwap';
    string private _symbol = 'BBOTS';
    uint8 private _decimals = 18;

    uint256 private _lastBurn;
    address private _pair;
    address private _rewardsEmission;

    uint public constant DAILY_BURN = 5;
    uint public constant DEX_BURNER = 30000;

    constructor() public {
        _lastBurn = block.number;
        uint256 initialSupply = 24 * 10**6 * 10**18;
        _balances[_msgSender()] = initialSupply;
        _totalSupply = _totalSupply.add(initialSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "BEP20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function mint(address account, uint256 amount) public onlyRewardsEmission {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function dexBurn() public {
        require(_pair != address(0), "BBOTS: the pair is zero address");
        require(_lastBurn.add(DEX_BURNER) <= block.number, "BBOTS: you can not call this function before 30000 blocks");

        uint256 calculcateBurn = _balances[_pair].mul(DAILY_BURN).div(100);

        _balances[_pair] = _balances[_pair].sub(calculcateBurn);
        _totalSupply = _totalSupply.sub(calculcateBurn);
        _lastBurn = block.number;

        IPancakePair pair = IPancakePair(_pair);
        pair.sync();

        _mint(_msgSender(), 40 * 10**18);
    }

    function getLastBurn() public view returns(uint256) {
        return _lastBurn;
    }

    function isRewardsEmission(address rewardsEmission) public view onlyOwner returns(bool) {
        return rewardsEmission == _rewardsEmission;
    }

    function isPair(address pair) public view onlyOwner returns(bool) {
        return pair == _pair;
    }

    function setPair(address pair) public onlyOwner {
        require(pair != address(0), "BBOTS: the pair is zero address");
        _pair = pair;
    }

    function setRewardsEmission(address rewardsEmission) public onlyOwner {
        require(rewardsEmission != address(0), "BBOTS: the dex is zero address");
        _rewardsEmission = rewardsEmission;
    }

    modifier onlyRewardsEmission() {
        require(_rewardsEmission == _msgSender(), "BBOTS: caller is not the rewards emission");
        _;
    }
}