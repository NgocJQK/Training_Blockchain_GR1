pragma solidity ^0.8.0; // phiên bản 
import "./IERC20.sol"; 
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    // ánh xạ lưu trữ thông tin về số dư của mỗi địa chỉ và giới hạn của chuyển tiền 
    // tăng/giảm số lượng chuyển tiền 
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    // khởi tạo tên và biểu tượng cho token 
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    // xuất thông tin Token
    // name Token
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    // tên Token
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    // số thập phân sử dụng Token 
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    // tổng cung của Token
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    // số dư của Token của 1 địa chỉ tài khoản account
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    // chuyển amount tới tài khoản có địa chỉ address to 
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender(); // lấy địa chỉ người gửi owner bằng hàm _msgSender()
        _transfer(owner, to, amount); 
        // thực hiện chuyển Token, trả về true báo chuyển thành công 
        return true;
    }

    // Hàm trả về số lượng token mà người được ủy quyền (owner) cho phép chi tiêu (spender) 
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender]; // ánh xạ lưu trữ thông tin về phép ủy quyền giữa các địa chỉ 
    }
    // choi phép người dùng thay đổi amount token mà người được ủy quyền spender có thể chi tiêu 
    // từ tài khoản của mình 
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();      // lấy địa chỉ 
        _approve(owner, spender, amount);  // cập nhật giá tị phép ủy quyền mới 
        return true;                       // trả về true báo thành công
    }

    // chuyển amount token từ tài khoản owner sang tài khoản to
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();                 // lấy dịa chỉ 
        _spendAllowance(from, spender, amount);         
        // kiểm tra và trừ số lượng token từ phép ủy quyền của form 
        _transfer(from, to, amount);
        // thực hiện chuyển token từ form tới to => trả về true nếu thành công 
        return true;
    }
    // tăng số lượng phép ủy quyền cho người chi tiêu spender thêm addedValue toke
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender(); // lấy địa chỉ    
        _approve(owner, spender, allowance(owner, spender) + addedValue); 
        // cập nhật lại giá trị phép ủy quyền mới
        return true; // thành công thì true 
    }
    // giảm số lượng phép ủy quyền cho người chi tiêu spender đi subtractedValue token
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender(); // lấy địa chỉ 
        // hàm lấy giá trị phép ủy quyền hiện tại 
        uint256 currentAllowance = allowance(owner, spender);  
        // hàm kiểm tra xem giá trị phép ủy quyền hiện tại có lớn hơn hoặc băng subtractedValue không
        // nếu mà không thì đưa ngoại lệ, còn nếu thành công thì thực hiện giảm giá trị phép ủy quyền đi 
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
        // trả về nếu thành công 
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        // chekc địa chỉ người gửi và người nhận có khác nhau hay không
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        // hàm ảo mà ghi đè trong hợp đồng kế thựa thực hiện điều chỉnh trước chuyển tiền 
        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        // kiểm tra số dư tài khoản người gửi có lớn hơn số lượng chuyển đi hay không
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount; // trừ số dư tài khoản người gửi đi
            _balances[to] += amount;                // cộng số dư tài khoản người nhận lên
        }
        
        // thông báo về chuyển tiền bằng cách phát ra 1 sự kiện Transfer 
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount); // ghi đè trong gợp đồng
    }
    // tạo mới 1 lượng amount token và ghi vào tài khoản chỉ định account 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address"); // check địa chỉ 
        // hàm ảo mà ghi đè trong hợp đồng kế thựa thực hiện điều chỉnh trước chuyển tiền 
        _beforeTokenTransfer(address(0), account, amount);
        // tạo mới token và cộng vào số lượng token hiện tại
        _totalSupply += amount;
        unchecked {
            // cộng số lượng token vào tài khoản chỉ định
            _balances[account] += amount;
        }
        // thông báo về chuyển tiền bằng cách phát ra 1 sự kiện Transfer
        emit Transfer(address(0), account, amount);
        // ghi đè trong gợp đồng
        _afterTokenTransfer(address(0), account, amount);
    }

    // đốt 1 lượng amount token từ tài khoản chỉ định account
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        // check địa chỉ 
        // hàm ảo mà ghi đè trong hợp đồng kế thựa thực hiện điều chỉnh trước chuyển tiền
        _beforeTokenTransfer(account, address(0), amount);
        // lấy ra số dư của địa chỉ tài khoản có lớn hơn or bằng amount không 
        uint256 accountBalance = _balances[account];


        require(accountBalance >= amount, "ERC20: burn amount exceeds balance"); // check ngoại lệ 

        unchecked {
            // trừ số dư tài khoản chỉ định đi
            _balances[account] = accountBalance - amount;
            
            // trừ số lượng token hiện tại đi
            _totalSupply -= amount;
        }
        // thông báo về chuyển tiền bằng cách phát ra 1 sự kiện Transfer
        emit Transfer(account, address(0), amount);
        // ghi đè trong gợp đồng
        _afterTokenTransfer(account, address(0), amount);
    }
    // thiết lập phép ủy quyền cho người sở hữu tài khoản owner ủy quyền cho người chi tiêu spender 1 lượng amount token
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        // check địa chỉ 
        // cho phép ủy quyền của owner cho spender, 
        // ánh xạ lưu trữ thông tin về số lượng token được ủy quyền cho mỗi địa chỉ người chi tiêu 
        _allowances[owner][spender] = amount;

        // phát đi sự kiện ủy quyền
        emit Approval(owner, spender, amount);
    }
    //chi tiêu số lượng amonut nhất định từ phép ủy quyền người sở hữu owner cho người chi tiêu spender 
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {

        uint256 currentAllowance = allowance(owner, spender);
        // check xem curentAllowance có khác với giá trị tối đa của uint256 hay không 
        if (currentAllowance != type(uint256).max) {

            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            // check ngoại lệ
            // trừ số lượng token đã chi tiêu đi
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {

    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {

    }
}