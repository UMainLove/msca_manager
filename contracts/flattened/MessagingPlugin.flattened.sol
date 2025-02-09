// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ^0.8.1 ^0.8.22 ^0.8.4;

// erc6900_smart_contracts_lib/ext/UUPSUpgradeable.sol

/// @notice UUPS proxy mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/UUPSUpgradeable.sol)
/// @author Modified from OpenZeppelin
/// (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol)
///
/// Note:
/// - This implementation is intended to be used with ERC1967 proxies.
/// See: `LibClone.deployERC1967` and related functions.
/// - This implementation is NOT compatible with legacy OpenZeppelin proxies
/// which do not store the implementation at `_ERC1967_IMPLEMENTATION_SLOT`.
abstract contract UUPSUpgradeable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The upgrade failed.
    error UpgradeFailed();

    /// @dev The call is from an unauthorized call context.
    error UnauthorizedCallContext();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         IMMUTABLES                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev For checking if the context is a delegate call.
    uint256 private immutable __self = uint256(uint160(address(this)));

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when the proxy's implementation is upgraded.
    event Upgraded(address indexed implementation);

    /// @dev `keccak256(bytes("Upgraded(address)"))`.
    uint256 private constant _UPGRADED_EVENT_SIGNATURE =
        0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ERC-1967 storage slot for the implementation in the proxy.
    /// `uint256(keccak256("eip1967.proxy.implementation")) - 1`.
    bytes32 internal constant _ERC1967_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      UUPS OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Please override this function to check if `msg.sender` is authorized
    /// to upgrade the proxy to `newImplementation`, reverting if not.
    /// ```
    ///     function _authorizeUpgrade(address) internal override onlyOwner {}
    /// ```
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /// @dev Returns the storage slot used by the implementation,
    /// as specified in [ERC1822](https://eips.ethereum.org/EIPS/eip-1822).
    ///
    /// Note: The `notDelegated` modifier prevents accidental upgrades to
    /// an implementation that is a proxy contract.
    function proxiableUUID() public view virtual notDelegated returns (bytes32) {
        // This function must always return `_ERC1967_IMPLEMENTATION_SLOT` to comply with ERC1967.
        return _ERC1967_IMPLEMENTATION_SLOT;
    }

    /// @dev Upgrades the proxy's implementation to `newImplementation`.
    /// Emits a {Upgraded} event.
    ///
    /// Note: Passing in empty `data` skips the delegatecall to `newImplementation`.
    function upgradeToAndCall(address newImplementation, bytes calldata data)
        public
        payable
        virtual
        onlyProxy
    {
        _authorizeUpgrade(newImplementation);
        /// @solidity memory-safe-assembly
        assembly {
            newImplementation := shr(96, shl(96, newImplementation)) // Clears upper 96 bits.
            mstore(0x01, 0x52d1902d) // `proxiableUUID()`.
            let s := _ERC1967_IMPLEMENTATION_SLOT
            // Check if `newImplementation` implements `proxiableUUID` correctly.
            if iszero(eq(mload(staticcall(gas(), newImplementation, 0x1d, 0x04, 0x01, 0x20)), s)) {
                mstore(0x01, 0x55299b49) // `UpgradeFailed()`.
                revert(0x1d, 0x04)
            }
            // Emit the {Upgraded} event.
            log2(codesize(), 0x00, _UPGRADED_EVENT_SIGNATURE, newImplementation)
            sstore(s, newImplementation) // Updates the implementation.

            // Perform a delegatecall to `newImplementation` if `data` is non-empty.
            if data.length {
                // Forwards the `data` to `newImplementation` via delegatecall.
                let m := mload(0x40)
                calldatacopy(m, data.offset, data.length)
                if iszero(delegatecall(gas(), newImplementation, m, data.length, codesize(), 0x00))
                {
                    // Bubble up the revert if the call reverts.
                    returndatacopy(m, 0x00, returndatasize())
                    revert(m, returndatasize())
                }
            }
        }
    }

    /// @dev Requires that the execution is performed through a proxy.
    modifier onlyProxy() {
        uint256 s = __self;
        /// @solidity memory-safe-assembly
        assembly {
            // To enable use cases with an immutable default implementation in the bytecode,
            // (see: ERC6551Proxy), we don't require that the proxy address must match the
            // value stored in the implementation slot, which may not be initialized.
            if eq(s, address()) {
                mstore(0x00, 0x9f03a026) // `UnauthorizedCallContext()`.
                revert(0x1c, 0x04)
            }
        }
        _;
    }

    /// @dev Requires that the execution is NOT performed via delegatecall.
    /// This is the opposite of `onlyProxy`.
    modifier notDelegated() {
        uint256 s = __self;
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(s, address())) {
                mstore(0x00, 0x9f03a026) // `UnauthorizedCallContext()`.
                revert(0x1c, 0x04)
            }
        }
        _;
    }
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/interfaces/IERC1271.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/token/ERC777/IERC777Recipient.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/utils/math/Math.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/utils/math/SignedMath.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// erc6900_smart_contracts_lib/src/interfaces/IAccountInitializable.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

/// @title Account Initializable Interface
interface IAccountInitializable {
    /// @notice Initialize the account with a set of plugins.
    /// @dev No dependencies may be provided with this installation.
    /// @param plugins The plugins to install.
    /// @param pluginInitData The plugin init data for each plugin.
    function initialize(address[] calldata plugins, bytes calldata pluginInitData) external;
}

// erc6900_smart_contracts_lib/src/interfaces/IPluginExecutor.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

/// @title Plugin Executor Interface
interface IPluginExecutor {
    /// @notice Execute a call from a plugin to another plugin, via an execution function installed on the account.
    /// @dev Plugins are not allowed to call native functions on the account. Permissions must be granted to the
    /// calling plugin for the call to go through.
    /// @param data The calldata to send to the plugin.
    /// @return The return data from the call.
    function executeFromPlugin(bytes calldata data) external payable returns (bytes memory);

    /// @notice Execute a call from a plugin to a non-plugin address.
    /// @dev If the target is a plugin, the call SHOULD revert. Permissions must be granted to the calling plugin
    /// for the call to go through.
    /// @param target The address to be called.
    /// @param value The value to send with the call.
    /// @param data The calldata to send to the target.
    /// @return The return data from the call.
    function executeFromPluginExternal(address target, uint256 value, bytes calldata data)
        external
        payable
        returns (bytes memory);
}

// erc6900_smart_contracts_lib/src/interfaces/IPluginManager.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

// Treats the first 20 bytes as an address, and the last byte as a function identifier.
type FunctionReference is bytes21;

/// @title Plugin Manager Interface
interface IPluginManager {
    event PluginInstalled(address indexed plugin, bytes32 manifestHash, FunctionReference[] dependencies);
    event PluginUninstalled(address indexed plugin, bool indexed onUninstallSucceeded);

    /// @notice Install a plugin to the modular account.
    /// @param plugin The plugin to install.
    /// @param manifestHash The hash of the plugin manifest.
    /// @param pluginInstallData Optional data to be decoded and used by the plugin to setup initial plugin data
    /// for the modular account.
    /// @param dependencies The dependencies of the plugin, as described in the manifest. Each FunctionReference
    /// MUST be composed of an installed plugin's address and a function ID of its validation function.
    function installPlugin(
        address plugin,
        bytes32 manifestHash,
        bytes calldata pluginInstallData,
        FunctionReference[] calldata dependencies
    ) external;

    /// @notice Uninstall a plugin from the modular account.
    /// @dev Uninstalling owner plugins outside of a replace operation via executeBatch risks losing the account!
    /// @param plugin The plugin to uninstall.
    /// @param config An optional, implementation-specific field that accounts may use to ensure consistency
    /// guarantees.
    /// @param pluginUninstallData Optional data to be decoded and used by the plugin to clear plugin data for the
    /// modular account.
    function uninstallPlugin(address plugin, bytes calldata config, bytes calldata pluginUninstallData) external;
}

// erc6900_smart_contracts_lib/src/interfaces/IStandardExecutor.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

struct Call {
    // The target address for the account to call.
    address target;
    // The value to send with the call.
    uint256 value;
    // The calldata for the call.
    bytes data;
}

/// @title Standard Executor Interface
interface IStandardExecutor {
    /// @notice Standard execute method.
    /// @dev If the target is a plugin, the call SHOULD revert.
    /// @param target The target address for the account to call.
    /// @param value The value to send with the call.
    /// @param data The calldata for the call.
    /// @return The return data from the call.
    function execute(address target, uint256 value, bytes calldata data) external payable returns (bytes memory);

    /// @notice Standard executeBatch method.
    /// @dev If the target is a plugin, the call SHOULD revert. If any of the calls revert, the entire batch MUST
    /// revert.
    /// @param calls The array of calls.
    /// @return An array containing the return data from the calls.
    function executeBatch(Call[] calldata calls) external payable returns (bytes[] memory);
}

// erc6900_smart_contracts_lib/src/interfaces/erc4337/UserOperation.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

/// @notice User Operation struct as defined in ERC-4337
struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

// erc6900_smart_contracts_lib/src/libraries/Constants.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// See LICENSE-MIT file for more information

type SetValue is bytes30;

/// @dev The sentinel value is used to indicate the head and tail of the list.
bytes32 constant SENTINEL_VALUE = bytes32(uint256(1));

/// @dev Removing the last element will result in this flag not being set correctly, but all operations will
/// function normally, albeit with one extra sload for getAll.
bytes32 constant HAS_NEXT_FLAG = bytes32(uint256(2));

/// @dev As defined by ERC-4337.
uint256 constant SIG_VALIDATION_PASSED = 0;
uint256 constant SIG_VALIDATION_FAILED = 1;

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/interfaces/IERC777Recipient.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC777Recipient.sol)

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/introspection/ERC165Checker.sol)

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(
        address account,
        bytes4[] memory interfaceIds
    ) internal view returns (bool[] memory) {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// erc6900_smart_contracts_lib/src/helpers/FunctionReferenceLib.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @title Function Reference Lib
/// @author Alchemy
library FunctionReferenceLib {
    // Empty or unset function reference.
    FunctionReference internal constant _EMPTY_FUNCTION_REFERENCE = FunctionReference.wrap(bytes21(0));
    // Magic value for runtime validation functions that always allow access.
    FunctionReference internal constant _RUNTIME_VALIDATION_ALWAYS_ALLOW =
        FunctionReference.wrap(bytes21(uint168(1)));
    // Magic value for hooks that should always revert.
    FunctionReference internal constant _PRE_HOOK_ALWAYS_DENY = FunctionReference.wrap(bytes21(uint168(2)));

    function pack(address addr, uint8 functionId) internal pure returns (FunctionReference) {
        return FunctionReference.wrap(bytes21(bytes20(addr)) | bytes21(uint168(functionId)));
    }

    function unpack(FunctionReference fr) internal pure returns (address addr, uint8 functionId) {
        bytes21 underlying = FunctionReference.unwrap(fr);
        addr = address(bytes20(underlying));
        functionId = uint8(bytes1(underlying << 160));
    }

    function isEmptyOrMagicValue(FunctionReference fr) internal pure returns (bool) {
        return FunctionReference.unwrap(fr) <= bytes21(uint168(2));
    }

    function isEmpty(FunctionReference fr) internal pure returns (bool) {
        return FunctionReference.unwrap(fr) == bytes21(0);
    }

    function eq(FunctionReference a, FunctionReference b) internal pure returns (bool) {
        return FunctionReference.unwrap(a) == FunctionReference.unwrap(b);
    }

    function notEq(FunctionReference a, FunctionReference b) internal pure returns (bool) {
        return FunctionReference.unwrap(a) != FunctionReference.unwrap(b);
    }
}

// erc6900_smart_contracts_lib/src/helpers/ValidationDataHelpers.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @dev This helper function assumes that uint160(validationData1) and uint160(validationData2) can only be 0 or 1
// solhint-disable-next-line private-vars-leading-underscore
function _coalescePreValidation(uint256 validationData1, uint256 validationData2)
    pure
    returns (uint256 resValidationData)
{
    uint48 validUntil1 = uint48(validationData1 >> 160);
    if (validUntil1 == 0) {
        validUntil1 = type(uint48).max;
    }
    uint48 validUntil2 = uint48(validationData2 >> 160);
    if (validUntil2 == 0) {
        validUntil2 = type(uint48).max;
    }
    resValidationData = ((validUntil1 > validUntil2) ? uint256(validUntil2) << 160 : uint256(validUntil1) << 160);

    uint48 validAfter1 = uint48(validationData1 >> 208);
    uint48 validAfter2 = uint48(validationData2 >> 208);

    resValidationData |= ((validAfter1 < validAfter2) ? uint256(validAfter2) << 208 : uint256(validAfter1) << 208);

    // Once we know that the authorizer field is 0 or 1, we can safely bubble up SIG_FAIL with bitwise OR
    resValidationData |= uint160(validationData1) | uint160(validationData2);
}

// solhint-disable-next-line private-vars-leading-underscore
function _coalesceValidation(uint256 preValidationData, uint256 validationData)
    pure
    returns (uint256 resValidationData)
{
    uint48 validUntil1 = uint48(preValidationData >> 160);
    if (validUntil1 == 0) {
        validUntil1 = type(uint48).max;
    }
    uint48 validUntil2 = uint48(validationData >> 160);
    if (validUntil2 == 0) {
        validUntil2 = type(uint48).max;
    }
    resValidationData = ((validUntil1 > validUntil2) ? uint256(validUntil2) << 160 : uint256(validUntil1) << 160);

    uint48 validAfter1 = uint48(preValidationData >> 208);
    uint48 validAfter2 = uint48(validationData >> 208);

    resValidationData |= ((validAfter1 < validAfter2) ? uint256(validAfter2) << 208 : uint256(validAfter1) << 208);

    // If prevalidation failed, bubble up failure
    resValidationData |=
        uint160(preValidationData) == SIG_VALIDATION_FAILED ? SIG_VALIDATION_FAILED : uint160(validationData);
}

// erc6900_smart_contracts_lib/src/interfaces/IAccountLoupe.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

/// @title Account Loupe Interface
interface IAccountLoupe {
    /// @notice Config for an execution function, given a selector.
    struct ExecutionFunctionConfig {
        address plugin;
        FunctionReference userOpValidationFunction;
        FunctionReference runtimeValidationFunction;
    }

    /// @notice Pre and post hooks for a given selector.
    /// @dev It's possible for one of either `preExecHook` or `postExecHook` to be empty.
    struct ExecutionHooks {
        FunctionReference preExecHook;
        FunctionReference postExecHook;
    }

    /// @notice Get the validation functions and plugin address for a selector.
    /// @dev If the selector is a native function, the plugin address will be the address of the account.
    /// @param selector The selector to get the configuration for.
    /// @return The configuration for this selector.
    function getExecutionFunctionConfig(bytes4 selector) external view returns (ExecutionFunctionConfig memory);

    /// @notice Get the pre and post execution hooks for a selector.
    /// @param selector The selector to get the hooks for.
    /// @return The pre and post execution hooks for this selector.
    function getExecutionHooks(bytes4 selector) external view returns (ExecutionHooks[] memory);

    /// @notice Get the pre user op and runtime validation hooks associated with a selector.
    /// @param selector The selector to get the hooks for.
    /// @return preUserOpValidationHooks The pre user op validation hooks for this selector.
    /// @return preRuntimeValidationHooks The pre runtime validation hooks for this selector.
    function getPreValidationHooks(bytes4 selector)
        external
        view
        returns (
            FunctionReference[] memory preUserOpValidationHooks,
            FunctionReference[] memory preRuntimeValidationHooks
        );

    /// @notice Get an array of all installed plugins.
    /// @return The addresses of all installed plugins.
    function getInstalledPlugins() external view returns (address[] memory);
}

// erc6900_smart_contracts_lib/src/interfaces/IPlugin.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

// Forge formatter will displace the first comment for the enum field out of the enum itself,
// so annotating here to prevent that.
// forgefmt: disable-start
enum ManifestAssociatedFunctionType {
    // Function is not defined.
    NONE,
    // Function belongs to this plugin.
    SELF,
    // Function belongs to an external plugin provided as a dependency during plugin installation. Plugins MAY depend
    // on external validation functions. It MUST NOT depend on external hooks, or installation will fail.
    DEPENDENCY,
    // Resolves to a magic value to always bypass runtime validation for a given function.
    // This is only assignable on runtime validation functions. If it were to be used on a user op validation function,
    // it would risk burning gas from the account. When used as a hook in any hook location, it is equivalent to not
    // setting a hook and is therefore disallowed.
    RUNTIME_VALIDATION_ALWAYS_ALLOW,
    // Resolves to a magic value to always fail in a hook for a given function.
    // This is only assignable to pre hooks (pre validation and pre execution). It should not be used on
    // validation functions themselves, because this is equivalent to leaving the validation functions unset.
    // It should not be used in post-exec hooks, because if it is known to always revert, that should happen
    // as early as possible to save gas.
    PRE_HOOK_ALWAYS_DENY
}
// forgefmt: disable-end

/// @dev For functions of type `ManifestAssociatedFunctionType.DEPENDENCY`, the MSCA MUST find the plugin address
/// of the function at `dependencies[dependencyIndex]` during the call to `installPlugin(config)`.
struct ManifestFunction {
    ManifestAssociatedFunctionType functionType;
    uint8 functionId;
    uint256 dependencyIndex;
}

struct ManifestAssociatedFunction {
    bytes4 executionSelector;
    ManifestFunction associatedFunction;
}

struct ManifestExecutionHook {
    bytes4 executionSelector;
    ManifestFunction preExecHook;
    ManifestFunction postExecHook;
}

struct ManifestExternalCallPermission {
    address externalAddress;
    bool permitAnySelector;
    bytes4[] selectors;
}

struct SelectorPermission {
    bytes4 functionSelector;
    string permissionDescription;
}

/// @dev A struct holding fields to describe the plugin in a purely view context. Intended for front end clients.
struct PluginMetadata {
    // A human-readable name of the plugin.
    string name;
    // The version of the plugin, following the semantic versioning scheme.
    string version;
    // The author field SHOULD be a username representing the identity of the user or organization
    // that created this plugin.
    string author;
    // String descriptions of the relative sensitivity of specific functions. The selectors MUST be selectors for
    // functions implemented by this plugin.
    SelectorPermission[] permissionDescriptors;
}

/// @dev A struct describing how the plugin should be installed on a modular account.
struct PluginManifest {
    // List of ERC-165 interface IDs to add to account to support introspection checks. This MUST NOT include
    // IPlugin's interface ID.
    bytes4[] interfaceIds;
    // If this plugin depends on other plugins' validation functions, the interface IDs of those plugins MUST be
    // provided here, with its position in the array matching the `dependencyIndex` members of `ManifestFunction`
    // structs used in the manifest.
    bytes4[] dependencyInterfaceIds;
    // Execution functions defined in this plugin to be installed on the MSCA.
    bytes4[] executionFunctions;
    // Plugin execution functions already installed on the MSCA that this plugin will be able to call.
    bytes4[] permittedExecutionSelectors;
    // Boolean to indicate whether the plugin can call any external address.
    bool permitAnyExternalAddress;
    // Boolean to indicate whether the plugin needs access to spend native tokens of the account. If false, the
    // plugin MUST still be able to spend up to the balance that it sends to the account in the same call.
    bool canSpendNativeToken;
    ManifestExternalCallPermission[] permittedExternalCalls;
    ManifestAssociatedFunction[] userOpValidationFunctions;
    ManifestAssociatedFunction[] runtimeValidationFunctions;
    ManifestAssociatedFunction[] preUserOpValidationHooks;
    ManifestAssociatedFunction[] preRuntimeValidationHooks;
    ManifestExecutionHook[] executionHooks;
}

/// @title Plugin Interface
interface IPlugin {
    /// @notice Initialize plugin data for the modular account.
    /// @dev Called by the modular account during `installPlugin`.
    /// @param data Optional bytes array to be decoded and used by the plugin to setup initial plugin data for the
    /// modular account.
    function onInstall(bytes calldata data) external;

    /// @notice Clear plugin data for the modular account.
    /// @dev Called by the modular account during `uninstallPlugin`.
    /// @param data Optional bytes array to be decoded and used by the plugin to clear plugin data for the modular
    /// account.
    function onUninstall(bytes calldata data) external;

    /// @notice Run the pre user operation validation hook specified by the `functionId`.
    /// @dev Pre user operation validation hooks MUST NOT return an authorizer value other than 0 or 1.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param userOp The user operation.
    /// @param userOpHash The user operation hash.
    /// @return Packed validation data for validAfter (6 bytes), validUntil (6 bytes), and authorizer (20 bytes).
    function preUserOpValidationHook(uint8 functionId, UserOperation calldata userOp, bytes32 userOpHash)
        external
        returns (uint256);

    /// @notice Run the user operation validationFunction specified by the `functionId`.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param userOp The user operation.
    /// @param userOpHash The user operation hash.
    /// @return Packed validation data for validAfter (6 bytes), validUntil (6 bytes), and authorizer (20 bytes).
    function userOpValidationFunction(uint8 functionId, UserOperation calldata userOp, bytes32 userOpHash)
        external
        returns (uint256);

    /// @notice Run the pre runtime validation hook specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param sender The caller address.
    /// @param value The call value.
    /// @param data The calldata sent.
    function preRuntimeValidationHook(uint8 functionId, address sender, uint256 value, bytes calldata data)
        external;

    /// @notice Run the runtime validationFunction specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param sender The caller address.
    /// @param value The call value.
    /// @param data The calldata sent.
    function runtimeValidationFunction(uint8 functionId, address sender, uint256 value, bytes calldata data)
        external;

    /// @notice Run the pre execution hook specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param sender The caller address.
    /// @param value The call value.
    /// @param data The calldata sent.
    /// @return Context to pass to a post execution hook, if present. An empty bytes array MAY be returned.
    function preExecutionHook(uint8 functionId, address sender, uint256 value, bytes calldata data)
        external
        returns (bytes memory);

    /// @notice Run the post execution hook specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param preExecHookData The context returned by its associated pre execution hook.
    function postExecutionHook(uint8 functionId, bytes calldata preExecHookData) external;

    /// @notice Describe the contents and intended configuration of the plugin.
    /// @dev This manifest MUST stay constant over time.
    /// @return A manifest describing the contents and intended configuration of the plugin.
    function pluginManifest() external pure returns (PluginManifest memory);

    /// @notice Describe the metadata of the plugin.
    /// @dev This metadata MUST stay constant over time.
    /// @return A metadata struct describing the plugin.
    function pluginMetadata() external pure returns (PluginMetadata memory);
}

// erc6900_smart_contracts_lib/src/interfaces/erc4337/IAggregator.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

/// @notice Interface for the ERC-4337 aggregator
interface IAggregator {
    function validateSignatures(UserOperation[] calldata, bytes calldata) external view;
    function validateUserOpSignature(UserOperation calldata) external view returns (bytes memory);
    function aggregateSignatures(UserOperation[] calldata) external view returns (bytes memory);
}

// erc6900_smart_contracts_lib/src/interfaces/erc4337/IEntryPoint.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

/// @notice Interface for the ERC-4337 entry point
interface IEntryPoint {
    error FailedOp(uint256 i, string s);

    function depositTo(address) external payable;
    function addStake(uint32) external payable;
    function unlockStake() external;
    function withdrawStake(address payable) external;
    function handleOps(UserOperation[] calldata, address payable) external;
    function getNonce(address, uint192) external view returns (uint256);
    function getUserOpHash(UserOperation calldata) external view returns (bytes32);
}

// erc6900_smart_contracts_lib/src/interfaces/erc4337/IPaymaster.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

/// @notice Interface for the ERC-4337 paymaster
interface IPaymaster {
    enum PostOpMode {
        opSucceeded,
        opReverted,
        postOpReverted
    }

    function validatePaymasterUserOp(UserOperation calldata, bytes32, uint256)
        external
        returns (bytes memory, uint256);

    function postOp(PostOpMode, bytes calldata, uint256) external;
}

// erc6900_smart_contracts_lib/src/libraries/AssociatedLinkedListSetLib.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// See LICENSE-MIT file for more information

/// @dev Type representing the set, which is just a storage slot placeholder like the solidity mapping type.
struct AssociatedLinkedListSet {
    bytes32 placeholder;
}

/// @title Associated Linked List Set Library
/// @author Alchemy
/// @notice Provides a set data structure that is enumerable and held in address-associated storage (per the
/// ERC-4337 spec)
library AssociatedLinkedListSetLib {
    // Mapping Entry Byte Layout
    // | value | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA____ |
    // | meta  | 0x____________________________________________________________BBBB |

    // Bit-layout of the meta bytes (2 bytes)
    // | user flags | 11111111 11111100 |
    // | has next   | 00000000 00000010 |
    // | sentinel   | 00000000 00000001 |

    // Mapping keys exclude the upper 15 bits of the meta bytes, which allows keys to be either a value or the
    // sentinel.

    // This cannot be evaluated at compile time because of its use in inline assembly.
    bytes4 internal constant _ASSOCIATED_STORAGE_PREFIX = 0xf938c976; // bytes4(keccak256("AssociatedLinkedListSet"))

    // A custom type representing the index of a storage slot
    type StoragePointer is bytes32;

    // A custom type representing a pointer to a location in memory beyond the current free memory pointer.
    // Holds a fixed-size buffer similar to "bytes memory", but without a length field.
    // Care must be taken when using these, as they may be overwritten if ANY memory is allocated after allocating
    // a TempBytesMemory.
    type TempBytesMemory is bytes32;

    // INTERNAL METHODS

    /// @notice Adds a value to a set.
    /// @param set The set to add the value to.
    /// @param associated The address the set is associated with.
    /// @param value The value to add.
    /// @return True if the value was added, false if the value cannot be added (already exists or is zero).
    function tryAdd(AssociatedLinkedListSet storage set, address associated, SetValue value)
        internal
        returns (bool)
    {
        bytes32 unwrappedKey = bytes32(SetValue.unwrap(value));
        if (unwrappedKey == bytes32(0)) {
            // Cannot add the zero value
            return false;
        }

        TempBytesMemory keyBuffer = _allocateTempKeyBuffer(set, associated);

        StoragePointer valueSlot = _mapLookup(keyBuffer, unwrappedKey);
        if (_load(valueSlot) != bytes32(0)) {
            // Entry already exists
            return false;
        }

        // Load the head of the set
        StoragePointer sentinelSlot = _mapLookup(keyBuffer, SENTINEL_VALUE);
        bytes32 prev = _load(sentinelSlot);
        if (prev == bytes32(0) || isSentinel(prev)) {
            // set is empty, need to do:
            // map[SENTINEL_VALUE] = unwrappedKey;
            // map[unwrappedKey] = SENTINEL_VALUE;
            _store(sentinelSlot, unwrappedKey);
            _store(valueSlot, SENTINEL_VALUE);
        } else {
            // set is not empty, need to do:
            // map[SENTINEL_VALUE] = unwrappedKey | HAS_NEXT_FLAG;
            // map[unwrappedKey] = prev;
            _store(sentinelSlot, unwrappedKey | HAS_NEXT_FLAG);
            _store(valueSlot, prev);
        }

        return true;
    }

    /// @notice Removes a value from a set.
    /// @dev This is an O(n) operation, where n is the number of elements in the set.
    /// @param set The set to remove the value from
    /// @param associated The address the set is associated with
    /// @param value The value to remove
    /// @return True if the value was removed, false if the value does not exist
    function tryRemove(AssociatedLinkedListSet storage set, address associated, SetValue value)
        internal
        returns (bool)
    {
        bytes32 unwrappedKey = bytes32(SetValue.unwrap(value));
        TempBytesMemory keyBuffer = _allocateTempKeyBuffer(set, associated);

        StoragePointer valueSlot = _mapLookup(keyBuffer, unwrappedKey);
        bytes32 nextValue = _load(valueSlot);
        if (unwrappedKey == bytes32(0) || nextValue == bytes32(0)) {
            // Entry does not exist
            return false;
        }

        bytes32 prevKey = SENTINEL_VALUE;
        bytes32 currentVal;
        do {
            // Load the current entry
            StoragePointer prevSlot = _mapLookup(keyBuffer, prevKey);
            currentVal = _load(prevSlot);
            bytes32 currentKey = clearFlags(currentVal);
            if (currentKey == unwrappedKey) {
                // Found the entry
                // Set the previous value's next value to the next value,
                // and the flags to the current value's flags.
                // and the next value's `hasNext` flag to determine whether or not the next value is (or points to)
                // the sentinel value.

                // Need to do:
                // map[prevKey] = clearFlags(nextValue) | getUserFlags(currentVal) | (nextValue & HAS_NEXT_FLAG);
                // map[currentKey] = bytes32(0);

                _store(prevSlot, clearFlags(nextValue) | getUserFlags(currentVal) | (nextValue & HAS_NEXT_FLAG));
                _store(valueSlot, bytes32(0));

                return true;
            }
            prevKey = currentKey;
        } while (!isSentinel(currentVal) && currentVal != bytes32(0));
        return false;
    }

    /// @notice Removes a value from a set, given the previous value in the set.
    /// @dev This is an O(1) operation but requires additional knowledge.
    /// @param set The set to remove the value from
    /// @param associated The address the set is associated with
    /// @param value The value to remove
    /// @param prev The previous value in the set
    /// @return True if the value was removed, false if the value does not exist
    function tryRemoveKnown(AssociatedLinkedListSet storage set, address associated, SetValue value, bytes32 prev)
        internal
        returns (bool)
    {
        bytes32 unwrappedKey = bytes32(SetValue.unwrap(value));
        TempBytesMemory keyBuffer = _allocateTempKeyBuffer(set, associated);

        prev = clearFlags(prev);

        if (prev == bytes32(0) || unwrappedKey == bytes32(0)) {
            return false;
        }

        // assert that the previous key's next value is the value to be removed
        StoragePointer prevSlot = _mapLookup(keyBuffer, prev);
        bytes32 currentValue = _load(prevSlot);
        if (clearFlags(currentValue) != unwrappedKey) {
            return false;
        }

        StoragePointer valueSlot = _mapLookup(keyBuffer, unwrappedKey);
        bytes32 next = _load(valueSlot);
        if (next == bytes32(0)) {
            // The set didn't actually contain the value
            return false;
        }

        // Need to do:
        // map[prev] = clearUserFlags(next) | getUserFlags(currentValue);
        // map[unwrappedKey] = bytes32(0);
        _store(prevSlot, clearUserFlags(next) | getUserFlags(currentValue));
        _store(valueSlot, bytes32(0));

        return true;
    }

    /// @notice Removes all values from a set.
    /// @dev This is an O(n) operation, where n is the number of elements in the set.
    /// @param set The set to remove the values from
    /// @param associated The address the set is associated with
    function clear(AssociatedLinkedListSet storage set, address associated) internal {
        TempBytesMemory keyBuffer = _allocateTempKeyBuffer(set, associated);

        bytes32 cursor = SENTINEL_VALUE;

        do {
            StoragePointer cursorSlot = _mapLookup(keyBuffer, cursor);
            bytes32 next = clearFlags(_load(cursorSlot));
            _store(cursorSlot, bytes32(0));
            cursor = next;
        } while (!isSentinel(cursor) && cursor != bytes32(0));
    }

    /// @notice Set the flags on a value in the set.
    /// @dev The user flags can only be set on the upper 14 bits, because the lower two are reserved for the
    /// sentinel and has next bit.
    /// @param set The set containing the value.
    /// @param associated The address the set is associated with.
    /// @param value The value to set the flags on.
    /// @param flags The flags to set.
    /// @return True if the set contains the value and the operation succeeds, false otherwise.
    function trySetFlags(AssociatedLinkedListSet storage set, address associated, SetValue value, uint16 flags)
        internal
        returns (bool)
    {
        bytes32 unwrappedKey = SetValue.unwrap(value);
        TempBytesMemory keyBuffer = _allocateTempKeyBuffer(set, associated);

        // Ignore the lower 2 bits.
        flags &= 0xFFFC;

        // If the set doesn't actually contain the value, return false;
        StoragePointer valueSlot = _mapLookup(keyBuffer, unwrappedKey);
        bytes32 next = _load(valueSlot);
        if (next == bytes32(0)) {
            return false;
        }

        // Set the flags
        _store(valueSlot, clearUserFlags(next) | bytes32(uint256(flags)));

        return true;
    }

    /// @notice Set the given flags on a value in the set, preserving the values of other flags.
    /// @dev The user flags can only be set on the upper 14 bits, because the lower two are reserved for the
    /// sentinel and has next bit.
    /// Short-circuits if the flags are already enabled, returning true.
    /// @param set The set containing the value.
    /// @param associated The address the set is associated with.
    /// @param value The value to enable the flags on.
    /// @param flags The flags to enable.
    /// @return True if the operation succeeds or short-circuits due to the flags already being enabled. False
    /// otherwise.
    function tryEnableFlags(AssociatedLinkedListSet storage set, address associated, SetValue value, uint16 flags)
        internal
        returns (bool)
    {
        flags &= 0xFFFC; // Allow short-circuit if lower bits are accidentally set
        uint16 currFlags = getFlags(set, associated, value);
        if (currFlags & flags == flags) return true; // flags are already enabled
        return trySetFlags(set, associated, value, currFlags | flags);
    }

    /// @notice Clear the given flags on a value in the set, preserving the values of other flags.
    /// @notice If the value is not in the set, this function will still return true.
    /// @dev The user flags can only be set on the upper 14 bits, because the lower two are reserved for the
    /// sentinel and has next bit.
    /// Short-circuits if the flags are already disabled, or if set does not contain the value. Short-circuits
    /// return true.
    /// @param set The set containing the value.
    /// @param associated The address the set is associated with.
    /// @param value The value to disable the flags on.
    /// @param flags The flags to disable.
    /// @return True if the operation succeeds, or short-circuits due to the flags already being disabled or if the
    /// set does not contain the value. False otherwise.
    function tryDisableFlags(AssociatedLinkedListSet storage set, address associated, SetValue value, uint16 flags)
        internal
        returns (bool)
    {
        flags &= 0xFFFC; // Allow short-circuit if lower bits are accidentally set
        uint16 currFlags = getFlags(set, associated, value);
        if (currFlags & flags == 0) return true; // flags are already disabled
        return trySetFlags(set, associated, value, currFlags & ~flags);
    }

    /// @notice Checks if a set contains a value
    /// @dev This method does not clear the upper bits of `value`, that is expected to be done as part of casting
    /// to the correct type. If this function is provided the sentinel value by using the upper bits, this function
    /// may returns `true`.
    /// @param set The set to check
    /// @param associated The address the set is associated with
    /// @param value The value to check for
    /// @return True if the set contains the value, false otherwise
    function contains(AssociatedLinkedListSet storage set, address associated, SetValue value)
        internal
        view
        returns (bool)
    {
        bytes32 unwrappedKey = bytes32(SetValue.unwrap(value));
        TempBytesMemory keyBuffer = _allocateTempKeyBuffer(set, associated);

        StoragePointer slot = _mapLookup(keyBuffer, unwrappedKey);
        return _load(slot) != bytes32(0);
    }

    /// @notice Checks if a set is empty
    /// @param set The set to check
    /// @param associated The address the set is associated with
    /// @return True if the set is empty, false otherwise
    function isEmpty(AssociatedLinkedListSet storage set, address associated) internal view returns (bool) {
        TempBytesMemory keyBuffer = _allocateTempKeyBuffer(set, associated);

        StoragePointer sentinelSlot = _mapLookup(keyBuffer, SENTINEL_VALUE);
        bytes32 val = _load(sentinelSlot);
        return val == bytes32(0) || isSentinel(val); // either the sentinel is unset, or points to itself
    }

    /// @notice Get the flags on a value in the set.
    /// @dev The reserved lower 2 bits will not be returned, as those are reserved for the sentinel and has next
    /// bit.
    /// @param set The set containing the value.
    /// @param associated The address the set is associated with.
    /// @param value The value to get the flags from.
    /// @return The flags set on the value.
    function getFlags(AssociatedLinkedListSet storage set, address associated, SetValue value)
        internal
        view
        returns (uint16)
    {
        bytes32 unwrappedKey = SetValue.unwrap(value);
        TempBytesMemory keyBuffer = _allocateTempKeyBuffer(set, associated);
        return uint16(uint256(_load(_mapLookup(keyBuffer, unwrappedKey))) & 0xFFFC);
    }

    /// @notice Check if the flags on a value are enabled.
    /// @dev The reserved lower 2 bits will be ignored, as those are reserved for the sentinel and has next bit.
    /// @param set The set containing the value.
    /// @param associated The address the set is associated with.
    /// @param value The value to check the flags on.
    /// @param flags The flags to check.
    /// @return True if all of the flags are enabled, false otherwise.
    function flagsEnabled(AssociatedLinkedListSet storage set, address associated, SetValue value, uint16 flags)
        internal
        view
        returns (bool)
    {
        flags &= 0xFFFC;
        return getFlags(set, associated, value) & flags == flags;
    }

    /// @notice Check if the flags on a value are disabled.
    /// @dev The reserved lower 2 bits will be ignored, as those are reserved for the sentinel and has next bit.
    /// @param set The set containing the value.
    /// @param associated The address the set is associated with.
    /// @param value The value to check the flags on.
    /// @param flags The flags to check.
    /// @return True if all of the flags are disabled, false otherwise.
    function flagsDisabled(AssociatedLinkedListSet storage set, address associated, SetValue value, uint16 flags)
        internal
        view
        returns (bool)
    {
        flags &= 0xFFFC;
        return ~(getFlags(set, associated, value)) & flags == flags;
    }

    /// @notice Gets all elements in a set.
    /// @dev This is an O(n) operation, where n is the number of elements in the set.
    /// @param set The set to get the elements of.
    /// @return ret An array of all elements in the set.
    function getAll(AssociatedLinkedListSet storage set, address associated)
        internal
        view
        returns (SetValue[] memory ret)
    {
        TempBytesMemory keyBuffer = _allocateTempKeyBuffer(set, associated);
        uint256 size;
        bytes32 cursor = _load(_mapLookup(keyBuffer, SENTINEL_VALUE));

        // Dynamically allocate the returned array as we iterate through the set, since we don't know the size
        // beforehand.
        // This is accomplished by first writing to memory after the free memory pointer,
        // then updating the free memory pointer to cover the newly-allocated data.
        // To the compiler, writes to memory after the free memory pointer are considered "memory safe".
        // See https://docs.soliditylang.org/en/v0.8.22/assembly.html#memory-safety
        // Stack variable lifting done when compiling with via-ir will only ever place variables into memory
        // locations below the current free memory pointer, so it is safe to compile this library with via-ir.
        // See https://docs.soliditylang.org/en/v0.8.22/yul.html#memoryguard
        assembly ("memory-safe") {
            // It is critical that no other memory allocations occur between:
            // -  loading the value of the free memory pointer into `ret`
            // -  updating the free memory pointer to point to the newly-allocated data, which is done after all
            // the values have been written.
            ret := mload(0x40)
            // Add an extra offset of 4 words to account for the length of the keyBuffer, since it will be used
            // for each lookup. If this value were written back to the free memory pointer, it would effectively
            // convert the keyBuffer into a "bytes memory" type. However, we don't actually write to the free
            // memory pointer until after all we've also allocated the entire return array.
            ret := add(ret, 0x80)
        }

        while (!isSentinel(cursor) && cursor != bytes32(0)) {
            unchecked {
                ++size;
            }
            bytes32 cleared = clearFlags(cursor);
            // Place the item into the return array manually. Since the size was just incremented, it will point to
            // the next location to write to.
            assembly ("memory-safe") {
                mstore(add(ret, mul(size, 0x20)), cleared)
            }
            if (hasNext(cursor)) {
                cursor = _load(_mapLookup(keyBuffer, cleared));
            } else {
                cursor = bytes32(0);
            }
        }

        assembly ("memory-safe") {
            // Update the free memory pointer with the now-known length of the array.
            mstore(0x40, add(ret, mul(add(size, 1), 0x20)))
            // Set the length of the array.
            mstore(ret, size)
        }
    }

    function isSentinel(bytes32 value) internal pure returns (bool ret) {
        assembly ("memory-safe") {
            ret := and(value, 1)
        }
    }

    function hasNext(bytes32 value) internal pure returns (bool) {
        return value & HAS_NEXT_FLAG != 0;
    }

    function clearFlags(bytes32 val) internal pure returns (bytes32) {
        return val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0001;
    }

    /// @dev Preserves the lower two bits
    function clearUserFlags(bytes32 val) internal pure returns (bytes32) {
        return val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0003;
    }

    function getUserFlags(bytes32 val) internal pure returns (bytes32) {
        return val & bytes32(uint256(0xFFFC));
    }

    // PRIVATE METHODS

    /// @notice Given an allocated key buffer, returns the storage slot for a given key
    function _mapLookup(TempBytesMemory keyBuffer, bytes32 value) private pure returns (StoragePointer slot) {
        assembly ("memory-safe") {
            // Store the value in the last word.
            mstore(add(keyBuffer, 0x60), value)
            slot := keccak256(keyBuffer, 0x80)
        }
    }

    /// @notice Allocates a key buffer for a given ID and associated address into scratch space memory.
    /// @dev The returned buffer must not be used if any additional memory is allocated after calling this
    /// function.
    /// @param set The set to allocate the key buffer for.
    /// @param associated The address the set is associated with.
    /// @return key A key buffer that can be used to lookup values in the set
    function _allocateTempKeyBuffer(AssociatedLinkedListSet storage set, address associated)
        private
        pure
        returns (TempBytesMemory key)
    {
        // Key derivation for an entry
        // Note: `||` refers to the concat operator
        // associated addr (left-padded) || prefix || uint224(0) batchIndex || set storage slot || entry
        // Word 1:
        // | zeros              | 0x000000000000000000000000________________________________________ |
        // | address            | 0x________________________AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA |
        // Word 2:
        // | prefix             | 0xPPPPPPPP________________________________________________________ |
        // | batch index (zero) | 0x________00000000000000000000000000000000000000000000000000000000 |
        // Word 3:
        // | set storage slot  | 0xSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS |
        // Word 4:
        // | entry value        | 0xVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV____ |
        // | entry meta         | 0x____________________________________________________________MMMM |

        // The batch index is for consistency with PluginStorageLib, and the prefix in front of it is
        // to prevent any potential crafted collisions where the batch index may be equal to storage slot
        // of the ALLS. The prefix is set to the upper bits of the batch index to make it infeasible to
        // reach from just incrementing the value.

        // This segment is memory-safe because it only uses the scratch space memory after the value of the free
        // memory pointer.
        // See https://docs.soliditylang.org/en/v0.8.22/assembly.html#memory-safety
        assembly ("memory-safe") {
            // Clean upper bits of arguments
            associated := and(associated, 0xffffffffffffffffffffffffffffffffffffffff)

            // Use memory past-the-free-memory-pointer without updating it, as this is just scratch space
            key := mload(0x40)
            // Store the associated address in the first word, left-padded with zeroes
            mstore(key, associated)
            // Store the prefix and a batch index of 0
            mstore(add(key, 0x20), _ASSOCIATED_STORAGE_PREFIX)
            // Store the list's storage slot in the third word
            mstore(add(key, 0x40), set.slot)
            // Leaves the last word open for the value entry
        }

        return key;
    }

    /// @dev Loads a value from storage
    function _load(StoragePointer ptr) private view returns (bytes32 val) {
        assembly ("memory-safe") {
            val := sload(ptr)
        }
    }

    /// @dev Writes a value into storage
    function _store(StoragePointer ptr, bytes32 val) private {
        assembly ("memory-safe") {
            sstore(ptr, val)
        }
    }
}

// erc6900_smart_contracts_lib/src/libraries/LinkedListSetLib.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// See LICENSE-MIT file for more information

struct LinkedListSet {
    // Byte Layout
    // | value | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA____ |
    // | meta  | 0x____________________________________________________________BBBB |

    // Bit-layout of the meta bytes (2 bytes)
    // | user flags | 11111111 11111100 |
    // | has next   | 00000000 00000010 |
    // | sentinel   | 00000000 00000001 |

    // Key excludes the meta bytes, except for the sentinel value, which is 0x1
    mapping(bytes32 => bytes32) map;
}

/// @title Linked List Set Library
/// @author Alchemy
/// @notice This library provides a set of functions for managing enumerable sets of bytes30 values.
library LinkedListSetLib {
    // INTERNAL METHODS

    /// @notice Add a value to a set.
    /// @param set The set to add the value to.
    /// @param value The value to add.
    /// @return True if the value was added, false if the value cannot be added (already exists or is zero).
    function tryAdd(LinkedListSet storage set, SetValue value) internal returns (bool) {
        mapping(bytes32 => bytes32) storage map = set.map;
        bytes32 unwrappedKey = SetValue.unwrap(value);
        if (unwrappedKey == bytes32(0) || map[unwrappedKey] != bytes32(0)) return false;

        bytes32 prev = map[SENTINEL_VALUE];
        if (prev == bytes32(0) || isSentinel(prev)) {
            // Set is empty
            map[SENTINEL_VALUE] = unwrappedKey;
            map[unwrappedKey] = SENTINEL_VALUE;
        } else {
            // set is not empty
            map[SENTINEL_VALUE] = unwrappedKey | HAS_NEXT_FLAG;
            map[unwrappedKey] = prev;
        }

        return true;
    }

    /// @notice Remove a value from a set.
    /// @dev This is an O(n) operation, where n is the number of elements in the set.
    /// @param set The set to remove the value from.
    /// @param value The value to remove.
    /// @return True if the value was removed, false if the value does not exist.
    function tryRemove(LinkedListSet storage set, SetValue value) internal returns (bool) {
        mapping(bytes32 => bytes32) storage map = set.map;
        bytes32 unwrappedKey = SetValue.unwrap(value);

        bytes32 nextValue = map[unwrappedKey];
        if (unwrappedKey == bytes32(0) || nextValue == bytes32(0)) return false;

        bytes32 prevKey = SENTINEL_VALUE;
        bytes32 currentVal;
        do {
            currentVal = map[prevKey];
            bytes32 currentKey = clearFlags(currentVal);
            if (currentKey == unwrappedKey) {
                // Set the previous value's next value to the next value,
                // and the flags to the current value's flags.
                // and the next value's `hasNext` flag to determine whether or not the next value is (or points to)
                // the sentinel value.
                map[prevKey] = clearFlags(nextValue) | getUserFlags(currentVal) | (nextValue & HAS_NEXT_FLAG);
                map[currentKey] = bytes32(0);

                return true;
            }
            prevKey = currentKey;
        } while (!isSentinel(currentVal) && currentVal != bytes32(0));
        return false;
    }

    /// @notice Remove a value from a set, given the previous value in the set.
    /// @dev This is an O(1) operation but requires additional knowledge.
    /// @param set The set to remove the value from.
    /// @param value The value to remove.
    /// @param prev The previous value in the set.
    /// @return True if the value was removed, false if the value does not exist.
    function tryRemoveKnown(LinkedListSet storage set, SetValue value, bytes32 prev) internal returns (bool) {
        mapping(bytes32 => bytes32) storage map = set.map;
        bytes32 unwrappedKey = SetValue.unwrap(value);

        // Clear the flag bits of prev
        prev = clearFlags(prev);

        if (prev == bytes32(0) || unwrappedKey == bytes32(0)) {
            return false;
        }

        // assert that the previous value's next value is the value to be removed
        bytes32 currentValue = map[prev];
        if (clearFlags(currentValue) != unwrappedKey) {
            return false;
        }

        bytes32 next = map[unwrappedKey];
        if (next == bytes32(0)) {
            // The set didn't actually contain the value
            return false;
        }

        map[prev] = clearUserFlags(next) | getUserFlags(currentValue);
        map[unwrappedKey] = bytes32(0);
        return true;
    }

    /// @notice Remove all values from a set.
    /// @dev This is an O(n) operation, where n is the number of elements in the set.
    /// @param set The set to remove the values from.
    function clear(LinkedListSet storage set) internal {
        mapping(bytes32 => bytes32) storage map = set.map;
        bytes32 cursor = SENTINEL_VALUE;

        do {
            bytes32 next = clearFlags(map[cursor]);
            map[cursor] = bytes32(0);
            cursor = next;
        } while (!isSentinel(cursor) && cursor != bytes32(0));
    }

    /// @notice Set the flags on a value in the set.
    /// @dev The user flags can only be set on the upper 14 bits, because the lower two are reserved for the
    /// sentinel and has next bit.
    /// @param set The set containing the value.
    /// @param value The value to set the flags on.
    /// @param flags The flags to set.
    /// @return True if the set contains the value and the operation succeeds, false otherwise.
    function trySetFlags(LinkedListSet storage set, SetValue value, uint16 flags) internal returns (bool) {
        mapping(bytes32 => bytes32) storage map = set.map;
        bytes32 unwrappedKey = SetValue.unwrap(value);

        // Ignore the lower 2 bits.
        flags &= 0xFFFC;

        // If the set doesn't actually contain the value, return false;
        bytes32 next = map[unwrappedKey];
        if (next == bytes32(0)) {
            return false;
        }

        // Set the flags
        map[unwrappedKey] = clearUserFlags(next) | bytes32(uint256(flags));

        return true;
    }

    /// @notice Set the given flags on a value in the set, preserving the values of other flags.
    /// @dev The user flags can only be set on the upper 14 bits, because the lower two are reserved for the
    /// sentinel and has next bit.
    /// Short-circuits if the flags are already enabled, returning true.
    /// @param set The set containing the value.
    /// @param value The value to enable the flags on.
    /// @param flags The flags to enable.
    /// @return True if the operation succeeds or short-circuits due to the flags already being enabled. False
    /// otherwise.
    function tryEnableFlags(LinkedListSet storage set, SetValue value, uint16 flags) internal returns (bool) {
        flags &= 0xFFFC; // Allow short-circuit if lower bits are accidentally set
        uint16 currFlags = getFlags(set, value);
        if (currFlags & flags == flags) return true; // flags are already enabled
        return trySetFlags(set, value, currFlags | flags);
    }

    /// @notice Clear the given flags on a value in the set, preserving the values of other flags.
    /// @notice If the value is not in the set, this function will still return true.
    /// @dev The user flags can only be set on the upper 14 bits, because the lower two are reserved for the
    /// sentinel and has next bit.
    /// Short-circuits if the flags are already disabled, or if set does not contain the value. Short-circuits
    /// return true.
    /// @param set The set containing the value.
    /// @param value The value to disable the flags on.
    /// @param flags The flags to disable.
    /// @return True if the operation succeeds, or short-circuits due to the flags already being disabled or if the
    /// set does not contain the value. False otherwise.
    function tryDisableFlags(LinkedListSet storage set, SetValue value, uint16 flags) internal returns (bool) {
        flags &= 0xFFFC; // Allow short-circuit if lower bits are accidentally set
        uint16 currFlags = getFlags(set, value);
        if (currFlags & flags == 0) return true; // flags are already disabled
        return trySetFlags(set, value, currFlags & ~flags);
    }

    /// @notice Check if a set contains a value.
    /// @dev This method does not clear the upper bits of `value`, that is expected to be done as part of casting
    /// to the correct type. If this function is provided the sentinel value by using the upper bits, this function
    /// may returns `true`.
    /// @param set The set to check.
    /// @param value The value to check for.
    /// @return True if the set contains the value, false otherwise.
    function contains(LinkedListSet storage set, SetValue value) internal view returns (bool) {
        mapping(bytes32 => bytes32) storage map = set.map;
        return map[SetValue.unwrap(value)] != bytes32(0);
    }

    /// @notice Check if a set is empty.
    /// @param set The set to check.
    /// @return True if the set is empty, false otherwise.
    function isEmpty(LinkedListSet storage set) internal view returns (bool) {
        mapping(bytes32 => bytes32) storage map = set.map;
        bytes32 val = map[SENTINEL_VALUE];
        return val == bytes32(0) || isSentinel(val); // either the sentinel is unset, or points to itself
    }

    /// @notice Get the flags on a value in the set.
    /// @dev The reserved lower 2 bits will not be returned, as those are reserved for the sentinel and has next
    /// bit.
    /// @param set The set containing the value.
    /// @param value The value to get the flags from.
    /// @return The flags set on the value.
    function getFlags(LinkedListSet storage set, SetValue value) internal view returns (uint16) {
        mapping(bytes32 => bytes32) storage map = set.map;
        bytes32 unwrappedKey = SetValue.unwrap(value);

        return uint16(uint256(map[unwrappedKey]) & 0xFFFC);
    }

    /// @notice Check if the flags on a value are enabled.
    /// @dev The reserved lower 2 bits will be ignored, as those are reserved for the sentinel and has next bit.
    /// @param set The set containing the value.
    /// @param value The value to check the flags on.
    /// @param flags The flags to check.
    /// @return True if all of the flags are enabled, false otherwise.
    function flagsEnabled(LinkedListSet storage set, SetValue value, uint16 flags) internal view returns (bool) {
        flags &= 0xFFFC;
        return getFlags(set, value) & flags == flags;
    }

    /// @notice Check if the flags on a value are disabled.
    /// @dev The reserved lower 2 bits will be ignored, as those are reserved for the sentinel and has next bit.
    /// @param set The set containing the value.
    /// @param value The value to check the flags on.
    /// @param flags The flags to check.
    /// @return True if all of the flags are disabled, false otherwise.
    function flagsDisabled(LinkedListSet storage set, SetValue value, uint16 flags) internal view returns (bool) {
        flags &= 0xFFFC;
        return ~(getFlags(set, value)) & flags == flags;
    }

    /// @notice Get all elements in a set.
    /// @dev This is an O(n) operation, where n is the number of elements in the set.
    /// @param set The set to get the elements of.
    /// @return ret An array of all elements in the set.
    function getAll(LinkedListSet storage set) internal view returns (SetValue[] memory ret) {
        mapping(bytes32 => bytes32) storage map = set.map;
        uint256 size;
        bytes32 cursor = map[SENTINEL_VALUE];

        // Dynamically allocate the returned array as we iterate through the set, since we don't know the size
        // beforehand.
        // This is accomplished by first writing to memory after the free memory pointer,
        // then updating the free memory pointer to cover the newly-allocated data.
        // To the compiler, writes to memory after the free memory pointer are considered "memory safe".
        // See https://docs.soliditylang.org/en/v0.8.22/assembly.html#memory-safety
        // Stack variable lifting done when compiling with via-ir will only ever place variables into memory
        // locations below the current free memory pointer, so it is safe to compile this library with via-ir.
        // See https://docs.soliditylang.org/en/v0.8.22/yul.html#memoryguard
        assembly ("memory-safe") {
            // It is critical that no other memory allocations occur between:
            // -  loading the value of the free memory pointer into `ret`
            // -  updating the free memory pointer to point to the newly-allocated data, which is done after all
            // the values have been written.
            ret := mload(0x40)
        }

        while (!isSentinel(cursor) && cursor != bytes32(0)) {
            unchecked {
                ++size;
            }
            bytes32 cleared = clearFlags(cursor);
            // Place the item into the return array manually. Since the size was just incremented, it will point to
            // the next location to write to.
            assembly ("memory-safe") {
                mstore(add(ret, mul(size, 0x20)), cleared)
            }
            if (hasNext(cursor)) {
                cursor = map[cleared];
            } else {
                cursor = bytes32(0);
            }
        }

        assembly ("memory-safe") {
            // Update the free memory pointer with the now-known length of the array.
            mstore(0x40, add(ret, mul(add(size, 1), 0x20)))
            // Set the length of the array.
            mstore(ret, size)
        }
    }

    function isSentinel(bytes32 value) internal pure returns (bool ret) {
        assembly ("memory-safe") {
            ret := and(value, 1)
        }
    }

    function hasNext(bytes32 value) internal pure returns (bool) {
        return value & HAS_NEXT_FLAG != 0;
    }

    function clearFlags(bytes32 val) internal pure returns (bytes32) {
        return val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0001;
    }

    /// @dev Preserves the lower two bits
    function clearUserFlags(bytes32 val) internal pure returns (bytes32) {
        return val & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0003;
    }

    function getUserFlags(bytes32 val) internal pure returns (bytes32) {
        return val & bytes32(uint256(0xFFFC));
    }
}

// erc6900_smart_contracts_lib/src/plugins/owner/IMultiOwnerPlugin.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

interface IMultiOwnerPlugin {
    enum FunctionId {
        RUNTIME_VALIDATION_OWNER_OR_SELF, // require owner or self access
        USER_OP_VALIDATION_OWNER // require owner access

    }

    /// @notice This event is emitted when owners of the account are updated.
    /// @param account The account whose ownership changed.
    /// @param addedOwners The address array of added owners.
    /// @param removedOwners The address array of removed owners.
    event OwnerUpdated(address indexed account, address[] addedOwners, address[] removedOwners);

    error InvalidOwner(address owner);
    error EmptyOwnersNotAllowed();
    error NotAuthorized();
    error OwnerDoesNotExist(address owner);

    /// @notice Update owners of the account. Owners can update owners.
    /// @dev This function is installed on the account as part of plugin installation, and should
    /// only be called from an account.
    /// @param ownersToAdd The address array of owners to be added.
    /// @param ownersToRemove The address array of owners to be removed.
    function updateOwners(address[] memory ownersToAdd, address[] memory ownersToRemove) external;

    /// @notice Gets the EIP712 domain
    /// @dev This implementation is different from typical 712 via its use of msg.sender instead. As such, it
    /// should only be called from the SCAs that has installed this. See ERC-5267.
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );

    /// @notice Check if an address is an owner of `account`.
    /// @param account The account to check.
    /// @param ownerToCheck The owner to check if it is an owner of the provided account.
    /// @return True if the address is an owner of the account.
    function isOwnerOf(address account, address ownerToCheck) external view returns (bool);

    /// @notice Get the owners of `account`.
    /// @param account The account to get the owners of.
    /// @return The addresses of the owners of the account.
    function ownersOf(address account) external view returns (address[] memory);

    /// @notice Returns the pre-image of the message hash
    /// @dev Assumes that the SCA's implementation of `domainSeparator` is this plugin's
    /// @param account SCA to build the message encoding for
    /// @param message Message that should be encoded.
    /// @return Encoded message.
    function encodeMessageData(address account, bytes memory message) external view returns (bytes memory);

    /// @notice Returns hash of a message that can be signed by owners.
    /// @param account SCA to build the message hash for
    /// @param message Message that should be hashed.
    /// @return Message hash.
    function getMessageHash(address account, bytes memory message) external view returns (bytes32);
}

// src/IMessagingPlugin.sol
/// This file is part of Modular Account v1.0.0
///
///
///

///
///

interface IMessagingPlugin {

    enum FunctionId {
        RUNTIME_VALIDATION_OWNER_OR_SELF, // require owner or self access
        USER_OP_VALIDATION_OWNER // require owner access

    }

    /// @notice This event is emitted when a message is sent
    /// @param from The account sending the message
    /// @param to The account receiving the message
    /// @param content The content of the message
    event MessageSent(address indexed from, address indexed to, string content);

    /// @notice Thrown when an operation is attempted by an unauthorized account
    /// @param from The unauthorized account address
    error NotAuthorized(address from);

    /// @notice Thrown when a message exceeds the maximum allowed length
    error MessageTooLong();

    /// @notice Thrown when attempting to send a message to an invalid recipient
    /// @param to The invalid recipient address
    error InvalidRecipient(address to);

    /// @notice Thrown when a message hash collision occurs
    /// @param messageHash The conflicting message hash
    error MessageHashCollision(bytes32 messageHash);

    /// @notice Thrown when message storage fails
    /// @param sender The sender of the message
    /// @param recipient The intended recipient
    error MessageStorageFailure(address sender, address recipient);

    /// @notice Thrown when account nonce reaches maximum value
    /// @param account The account with nonce overflow
    error AccountNonceOverflow(address account);

    /// @notice Thrown when message nonce reaches maximum value
    /// @param account The account with message nonce overflow
    error MessageNonceOverflow(address account);

    /// @notice Send a message to another account
    /// @dev Only initialized accounts can send/receive messages
    /// @param to The recipient address
    /// @param content The message content
    /// @dev Emits MessageSent event on success
    /// @dev Reverts if:
    ///      - Sender is not initialized (NotAuthorized)
    ///      - Recipient is not initialized (InvalidRecipient)
    ///      - Message content exceeds MAX_MESSAGE_LENGTH (MessageTooLong)
    ///      - Message hash collision occurs (MessageHashCollision)
    ///      - Message storage fails (MessageStorageFailure)
    ///      - Message nonce overflows (MessageNonceOverflow)
    function sendMessage(address to, string calldata content) external;

    /// @notice Gets the EIP712 domain
    /// @dev This implementation is different from typical 712 via its use of msg.sender instead. 
    /// Should only be called from SCAs that have installed this. See ERC-5267.
    /// @return fields Domain fields bitmap
    /// @return name Domain name
    /// @return version Domain version
    /// @return chainId Chain ID
    /// @return verifyingContract Address of the verifying contract
    /// @return salt Domain salt
    /// @return extensions Domain extensions
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );

    /// @notice Get chat history with another account
    /// @dev Returns messages in chronological order by timestamp
    /// @param with The address to get chat history with
    /// @return messages Array of messages between the two accounts
    /// @dev Messages are sorted by timestamp in ascending order
    /// @dev Only returns messages where either:
    ///      - msg.sender is the sender and 'with' is the recipient
    ///      - 'with' is the sender and msg.sender is the recipient
    function getChat(address with) external view returns (string[] memory messages);

    /// @notice Get hash of message used in typed data signing
    /// @param account The account address
    /// @param message The message to hash
    /// @return The computed message hash
    function getMessageHash(address account, bytes memory message) external view returns (bytes32);

    /// @notice Encode message data according to EIP-712 specification
    /// @param account The account address
    /// @param message The message to encode
    /// @return The encoded message data
    function encodeMessageData(address account, bytes memory message) external view returns (bytes memory);
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/interfaces/IERC1155Receiver.sol

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155Receiver.sol)

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/utils/Strings.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// erc6900_smart_contracts_lib/src/interfaces/IAccountView.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

/// @title Account View Interface
interface IAccountView {
    /// @notice Get the entry point for this account.
    /// @return entryPoint The entry point for this account.
    function entryPoint() external view returns (IEntryPoint);

    /// @notice Get the account nonce.
    /// @dev Uses key 0.
    /// @return nonce The next account nonce.
    function getNonce() external view returns (uint256);
}

// erc6900_smart_contracts_lib/src/interfaces/erc4337/IAccount.sol
// This work is marked with CC0 1.0 Universal.
//

//
// To view a copy of this license, visit http://creativecommons.org/publicdomain/zero/1.0

/// @notice Interface for the ERC-4337 account
interface IAccount {
    /// @notice Validates a user operation, presumably by checking the signature and nonce. The entry point will
    /// call this function to ensure that a user operation sent to it has been authorized, and thus that it should
    /// call the account with the operation's call data and charge the account for  gas in the absense of a
    /// paymaster. If the signature is correctly formatted but invalid, this should return 1; other failures may
    /// revert instead. In the case of a success, this can optionally return a signature aggregator and/or a time
    /// range during which the operation is valid.
    /// @param userOp the operation to be validated
    /// @param userOpHash hash of the operation
    /// @param missingAccountFunds amount that the account must send to the entry point as part of validation to
    /// pay for gas
    /// @return validationData Either 1 for an invalid signature, or a packed structure containing an optional
    /// aggregator address in the first 20 bytes followed by two 6-byte timestamps representing the "validUntil"
    /// and "validAfter" times at which the operation is valid (a "validUntil" of 0 means it is valid forever).
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData);
}

// erc6900_smart_contracts_lib/src/libraries/CountableLinkedListSetLib.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// See LICENSE-MIT file for more information

/// @title Countable Linked List Set Library
/// @author Alchemy
/// @notice This library adds the ability to count the number of occurrences of a value in a linked list set.
/// @dev The counter is stored in the upper 8 bits of the the flag bytes, so the maximum value of the counter
/// is 255. This means each value can be included a maximum of 256 times in the set, as the counter is 0 when
/// the value is first added.
library CountableLinkedListSetLib {
    using LinkedListSetLib for LinkedListSet;

    /// @notice Increment an existing value in the set, or add it if it doesn't exist.
    /// @dev The counter is stored in the upper 8 bits of the the flag bytes. Because this library repurposes a
    /// portion of the flag bytes to store the counter, it's important to not use the upper 8 bits to store flags.
    /// Any existing flags on the upper 8 bits will be interpreted as part of the counter.
    /// @param set The set to increment (or add) the value in.
    /// @param value The value to increment (or add).
    /// @return True if the value was incremented or added, false otherwise.
    function tryIncrement(LinkedListSet storage set, SetValue value) internal returns (bool) {
        if (!set.contains(value)) {
            return set.tryAdd(value);
        }
        uint16 flags = set.getFlags(value);
        if (flags > 0xFEFF) {
            // The counter is at its maximum value, so don't increment it.
            return false;
        }
        unchecked {
            flags += 0x100;
        }
        return set.trySetFlags(value, flags);
    }

    /// @notice Decrement an existing value in the set, or remove it if the count has reached 0.
    /// @dev The counter is stored in the upper 8 bits of the the flag bytes. Because this library repurposes a
    /// portion of the flag bytes to store the counter, it's important to not use the upper 8 bits to store flags.
    /// Any existing flags on the upper 8 bits will be interpreted as part of the counter.
    /// @param set The set to decrement (or remove) the value in.
    /// @param value The value to decrement (or remove).
    /// @return True if the value was decremented or removed, false otherwise.
    function tryDecrement(LinkedListSet storage set, SetValue value) internal returns (bool) {
        if (!set.contains(value)) {
            return false;
        }
        uint16 flags = set.getFlags(value);
        if (flags < 0x100) {
            // The counter is 0, so remove the value.
            return set.tryRemove(value);
        }
        unchecked {
            flags -= 0x100;
        }
        return set.trySetFlags(value, flags);
    }

    /// @notice Get the number of occurrences of a value in the set.
    /// @dev The counter is stored in the upper 8 bits of the the flag bytes. Because this library repurposes a
    /// portion of the flag bytes to store the counter, it's important to not use the upper 8 bits to store flags.
    /// Any existing flags on the upper 8 bits will be interpreted as part of the counter.
    /// @return The number of occurrences of the value in the set.
    function getCount(LinkedListSet storage set, SetValue value) internal view returns (uint256) {
        if (!set.contains(value)) {
            return 0;
        }
        unchecked {
            return (set.getFlags(value) >> 8) + 1;
        }
    }
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// erc6900_smart_contracts_lib/src/helpers/CastLib.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @title Cast Library
/// @author Alchemy
/// @notice Library for various data type conversions.
library CastLib {
    /// @dev Input array is not verified. If called with non FunctionReference type array input, return data will
    /// be incorrect.
    function toFunctionReferenceArray(SetValue[] memory vals)
        internal
        pure
        returns (FunctionReference[] memory ret)
    {
        assembly ("memory-safe") {
            ret := vals
        }
    }

    /// @dev Input array is not verified. If used with non address type array input, return data will be incorrect.
    function toAddressArray(SetValue[] memory values) internal pure returns (address[] memory addresses) {
        bytes32[] memory valuesBytes;

        assembly ("memory-safe") {
            valuesBytes := values
        }

        uint256 length = values.length;
        for (uint256 i = 0; i < length; ++i) {
            valuesBytes[i] >>= 96;
        }

        assembly ("memory-safe") {
            addresses := valuesBytes
        }

        return addresses;
    }

    function toSetValue(FunctionReference functionReference) internal pure returns (SetValue) {
        return SetValue.wrap(bytes30(FunctionReference.unwrap(functionReference)));
    }

    function toSetValue(address value) internal pure returns (SetValue) {
        return SetValue.wrap(bytes30(bytes20(value)));
    }
}

// erc6900_smart_contracts_lib/src/account/AccountExecutor.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @title Account Executor
/// @author Alchemy
/// @notice Provides internal functions for executing calls on a modular account.
abstract contract AccountExecutor {
    error PluginCallDenied(address plugin);

    /// @dev If the target is a plugin (as determined by its support for the IPlugin interface), revert.
    /// This prevents the modular account from calling plugins (both installed and uninstalled) outside
    /// of the normal flow (via execution functions installed on the account), which could lead to data
    /// inconsistencies and unexpected behavior.
    /// @param target The address of the contract to call.
    /// @param value The value to send with the call.
    /// @param data The call data.
    /// @return result The return data of the call, or the error message from the call if call reverts.
    function _exec(address target, uint256 value, bytes memory data) internal returns (bytes memory result) {
        if (ERC165Checker.supportsInterface(target, type(IPlugin).interfaceId)) {
            revert PluginCallDenied(target);
        }

        bool success;
        (success, result) = target.call{value: value}(data);

        if (!success) {
            // Directly bubble up revert messages
            assembly ("memory-safe") {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /// @dev Performs an `_executeRaw` for a call buffer holding a call to one of:
    /// - Pre Runtime Validation Hook
    /// - Runtime Validation
    /// - Pre Execution Hook
    /// And if it fails, reverts with the appropriate custom error.
    function _executeRuntimePluginFunction(bytes memory buffer, address plugin, bytes4 errorSelector) internal {
        if (!_executeRaw(plugin, buffer)) {
            _revertOnRuntimePluginFunctionFail(buffer, plugin, errorSelector);
        }
    }

    function _executeRaw(address plugin, bytes memory buffer) internal returns (bool success) {
        assembly ("memory-safe") {
            success :=
                call(
                    gas(),
                    plugin,
                    /*value*/
                    0,
                    /*argOffset*/
                    add(buffer, 0x20), // jump over 32 bytes for length
                    /*argSize*/
                    mload(buffer),
                    /*retOffset*/
                    0,
                    /*retSize*/
                    0
                )
        }
    }

    function _executeUserOpPluginFunction(bytes memory buffer, address plugin)
        internal
        returns (uint256 validationData)
    {
        assembly ("memory-safe") {
            switch and(
                gt(returndatasize(), 0x1f),
                call(
                    /*forward all gas, but can't use gas opcode due to validation opcode restrictions*/
                    not(0),
                    plugin,
                    /*value*/
                    0,
                    /*argOffset*/
                    add(buffer, 0x20), // jump over 32 bytes for length
                    /*argSize*/
                    mload(buffer),
                    /*retOffset*/
                    0,
                    /*retSize*/
                    0x20
                )
            )
            case 0 {
                // Bubble up the revert if the call reverts.
                let m := mload(0x40)
                returndatacopy(m, 0x00, returndatasize())
                revert(m, returndatasize())
            }
            default {
                // Otherwise, we return the first word of the return data as the validation data
                validationData := mload(0)
            }
        }
    }

    function _allocateRuntimeCallBuffer(bytes calldata data) internal view returns (bytes memory buffer) {
        buffer = abi.encodeWithSelector(bytes4(0), 0, msg.sender, msg.value, data);
    }

    function _allocateUserOpCallBuffer(bytes4 selector, UserOperation calldata userOp, bytes32 userOpHash)
        internal
        pure
        returns (bytes memory buffer)
    {
        buffer = abi.encodeWithSelector(selector, 0, userOp, userOpHash);
    }

    /// @dev Updates which plugin function the buffer will call.
    function _updatePluginCallBufferSelector(bytes memory buffer, bytes4 pluginSelector) internal pure {
        assembly ("memory-safe") {
            // We only want to write to the first 4 bytes, so we first load the first word,
            // mask out the fist 4 bytes, then OR in the new selector.
            let existingWord := mload(add(buffer, 0x20))
            // Clear the upper 4 bytes of the existing word
            existingWord := shr(32, shl(32, existingWord))
            // Clear the lower 28 bytes of the selector
            pluginSelector := shl(224, shr(224, pluginSelector))
            // OR in the new selector
            existingWord := or(existingWord, pluginSelector)
            mstore(add(buffer, 0x20), existingWord)
        }
    }

    function _updatePluginCallBufferFunctionId(bytes memory buffer, uint8 functionId) internal pure {
        assembly ("memory-safe") {
            // The function ID is a uint8 type, which is left-padded.
            // We do want to mask it, however, because this is an internal function and the upper bits may not be
            // cleared.
            mstore(add(buffer, 0x24), and(functionId, 0xff))
        }
    }

    /// @dev Re-interpret the existing call buffer as just a bytes memory hold msg.data.
    /// Since it's already there, and we don't plan on using the buffer again, we can write over the other fields
    /// to store calldata length before the data, then return a new memory pointer holding the length.
    function _convertRuntimeCallBufferToExecBuffer(bytes memory runtimeCallBuffer)
        internal
        pure
        returns (bytes memory execCallBuffer)
    {
        if (runtimeCallBuffer.length == 0) {
            // There was no existing call buffer. This case is never reached in actual code, but in the event that
            // it would be, we would need to re-collect all the calldata.
            execCallBuffer = msg.data;
        } else {
            assembly ("memory-safe") {
                // Skip forward to point to the new "length-holding" field.
                // Since the existing buffer is already ABI-encoded, we can just skip to the inner callData field.
                // This field is location  bytes ahead. It skips over:
                // - (32 bytes) The original buffer's length field
                // - (4 bytes) Selector
                // - (32 bytes) Function id
                // - (32 bytes) Sender
                // - (32 bytes) Value
                // - (32 bytes) data offset
                // Total: 164 bytes
                execCallBuffer := add(runtimeCallBuffer, 164)
            }
        }
    }

    /// @dev Used by pre exec hooks to store data for post exec hooks.
    function _collectReturnData() internal pure returns (bytes memory returnData) {
        assembly ("memory-safe") {
            // Allocate a buffer of that size, advancing the memory pointer to the nearest word
            returnData := mload(0x40)
            mstore(returnData, returndatasize())
            mstore(0x40, and(add(add(returnData, returndatasize()), 0x3f), not(0x1f)))

            // Copy over the return data
            returndatacopy(add(returnData, 0x20), 0, returndatasize())
        }
    }

    /// @dev This function reverts with one of the following custom error types:
    /// - PreRuntimeValidationHookFailed
    /// - RuntimeValidationFunctionReverted
    /// - PreExecHookReverted
    /// Since they all take the same parameters, we can just switch the selector as needed.
    /// The last parameter, revertReason, is copied from return data.
    function _revertOnRuntimePluginFunctionFail(bytes memory buffer, address plugin, bytes4 errorSelector)
        internal
        pure
    {
        assembly ("memory-safe") {
            // Call failed, revert with the established error format and the provided selector
            // The error format is:
            // - Custom error selector
            // - plugin address
            // - function id
            // - byte offset and length of revert reason
            // - byte memory revertReason
            // Total size: 132 bytes (4 byte selector + 4 * 32 byte words) + length of revert reason
            let errorStart := mload(0x40)
            // We add the extra size for the abi encoded fields at the same time as the selector,
            // which is after the word-alignment step.
            // Pad errorSize to nearest word
            let errorSize := and(add(returndatasize(), 0x1f), not(0x1f))
            // Add the abi-encoded fields length (128 bytes) and the selector's size (4 bytes)
            // to the error size.
            errorSize := add(errorSize, 132)
            // Store the selector in the start of the error buffer.
            // Any set lower bits will be cleared with the subsequest mstore.
            mstore(errorStart, errorSelector)
            mstore(add(errorStart, 0x04), plugin)
            // Store the function id in the next word, as retrieved from the buffer
            mstore(add(errorStart, 0x24), mload(add(buffer, 0x24)))
            // Store the offset and length of the revert reason in the next two words
            mstore(add(errorStart, 0x44), 0x60)
            mstore(add(errorStart, 0x64), returndatasize())

            // Copy over the revert reason
            returndatacopy(add(errorStart, 0x84), 0, returndatasize())

            // Revert
            revert(errorStart, errorSize)
        }
    }
}

// erc6900_smart_contracts_lib/src/plugins/BasePlugin.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @title Base contract for plugins
/// @dev Implements ERC-165 to support IPlugin's interface, which is a requirement
/// for plugin installation. This also ensures that plugin interactions cannot
/// happen via the standard execution funtions `execute`, `executeBatch`, and `executeFromPluginExternal`.
/// Note that the plugins implement BasePlugins cannot be installed when creating an account (aka installed in the
/// account constructor) unless onInstall is overriden without checking codesize of caller (account). Checking
/// codesize of account is to prevent EOA from accidentally calling plugin and initiate states which will make it
/// unusable in the future when EOA can be upgraded into an smart contract account.
abstract contract BasePlugin is ERC165, IPlugin {
    error AlreadyInitialized();
    error InvalidAction();
    error NotContractCaller(address caller);
    error NotImplemented(bytes4 selector, uint8 functionId);
    error NotInitialized();

    modifier isNotInitialized(address account) {
        if (_isInitialized(account)) {
            revert AlreadyInitialized();
        }
        _;
    }

    modifier isInitialized(address account) {
        if (!_isInitialized(account)) {
            revert NotInitialized();
        }
        _;
    }

    modifier staysInitialized(address account) {
        if (!_isInitialized(account)) {
            revert NotInitialized();
        }
        _;
        if (!_isInitialized(account)) {
            revert InvalidAction();
        }
    }

    /// @notice Initialize plugin data for the modular account.
    /// @dev Called by the modular account during `installPlugin`.
    /// @param data Optional bytes array to be decoded and used by the plugin to setup initial plugin data for the
    /// modular account.
    function onInstall(bytes calldata data) external virtual {
        if (msg.sender.code.length == 0) {
            revert NotContractCaller(msg.sender);
        }
        _onInstall(data);
    }

    /// @notice Clear plugin data for the modular account.
    /// @dev Called by the modular account during `uninstallPlugin`.
    /// @param data Optional bytes array to be decoded and used by the plugin to clear plugin data for the modular
    /// account.
    function onUninstall(bytes calldata data) external virtual {
        (data);
        revert NotImplemented(msg.sig, 0);
    }

    /// @notice Run the pre user operation validation hook specified by the `functionId`.
    /// @dev Pre user operation validation hooks MUST NOT return an authorizer value other than 0 or 1.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param userOp The user operation.
    /// @param userOpHash The user operation hash.
    /// @return Packed validation data for validAfter (6 bytes), validUntil (6 bytes), and authorizer (20 bytes).
    function preUserOpValidationHook(uint8 functionId, UserOperation calldata userOp, bytes32 userOpHash)
        external
        virtual
        returns (uint256)
    {
        (functionId, userOp, userOpHash);
        revert NotImplemented(msg.sig, functionId);
    }

    /// @notice Run the user operation validationFunction specified by the `functionId`.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param userOp The user operation.
    /// @param userOpHash The user operation hash.
    /// @return Packed validation data for validAfter (6 bytes), validUntil (6 bytes), and authorizer (20 bytes).
    function userOpValidationFunction(uint8 functionId, UserOperation calldata userOp, bytes32 userOpHash)
        external
        virtual
        returns (uint256)
    {
        (functionId, userOp, userOpHash);
        revert NotImplemented(msg.sig, functionId);
    }

    /// @notice Run the pre runtime validation hook specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param sender The caller address.
    /// @param value The call value.
    /// @param data The calldata sent.
    function preRuntimeValidationHook(uint8 functionId, address sender, uint256 value, bytes calldata data)
        external
        virtual
    {
        (functionId, sender, value, data);
        revert NotImplemented(msg.sig, functionId);
    }

    /// @notice Run the runtime validationFunction specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param sender The caller address.
    /// @param value The call value.
    /// @param data The calldata sent.
    function runtimeValidationFunction(uint8 functionId, address sender, uint256 value, bytes calldata data)
        external
        virtual
    {
        (functionId, sender, value, data);
        revert NotImplemented(msg.sig, functionId);
    }

    /// @notice Run the pre execution hook specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param sender The caller address.
    /// @param value The call value.
    /// @param data The calldata sent.
    /// @return Context to pass to a post execution hook, if present. An empty bytes array MAY be returned.
    function preExecutionHook(uint8 functionId, address sender, uint256 value, bytes calldata data)
        external
        virtual
        returns (bytes memory)
    {
        (functionId, sender, value, data);
        revert NotImplemented(msg.sig, functionId);
    }

    /// @notice Run the post execution hook specified by the `functionId`.
    /// @dev To indicate the entire call should revert, the function MUST revert.
    /// @param functionId An identifier that routes the call to different internal implementations, should there be
    /// more than one.
    /// @param preExecHookData The context returned by its associated pre execution hook.
    function postExecutionHook(uint8 functionId, bytes calldata preExecHookData) external virtual {
        (functionId, preExecHookData);
        revert NotImplemented(msg.sig, functionId);
    }

    /// @notice Describe the contents and intended configuration of the plugin.
    /// @dev This manifest MUST stay constant over time.
    /// @return A manifest describing the contents and intended configuration of the plugin.
    function pluginManifest() external pure virtual returns (PluginManifest memory) {
        revert NotImplemented(msg.sig, 0);
    }

    /// @notice Describe the metadata of the plugin.
    /// @dev This metadata MUST stay constant over time.
    /// @return A metadata struct describing the plugin.
    function pluginMetadata() external pure virtual returns (PluginMetadata memory);

    /// @dev Returns true if this contract implements the interface defined by
    /// `interfaceId`. See the corresponding
    /// https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
    /// to learn more about how these ids are created.
    ///
    /// This function call must use less than 30 000 gas.
    ///
    /// Supporting the IPlugin interface is a requirement for plugin installation. This is also used
    /// by the modular account to prevent standard execution functions `execute`, `executeBatch`, and
    /// `executeFromPluginExternal` from making calls to plugins.
    /// @param interfaceId The interface ID to check for support.
    /// @return True if the contract supports `interfaceId`.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IPlugin).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Initialize plugin data for the modular account.
    /// @dev Called by the modular account during `installPlugin`.
    /// @param data Optional bytes array to be decoded and used by the plugin to setup initial plugin data for the
    /// modular account.
    function _onInstall(bytes calldata data) internal virtual {
        (data);
        revert NotImplemented(msg.sig, 0);
    }

    /// @notice Check if the account has initialized this plugin yet
    /// @dev This function should be overwritten for plugins that have state-changing onInstall's
    /// @param account The account to check
    /// @return True if the account has initialized this plugin
    // solhint-disable-next-line no-empty-blocks
    function _isInitialized(address account) internal view virtual returns (bool) {}
}

// erc6900_smart_contracts_lib/lib/openzeppelin-contracts/contracts/utils/cryptography/SignatureChecker.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// erc6900_smart_contracts_lib/src/account/AccountStorageV1.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @title Account Storage V1
/// @author Alchemy
/// @notice Contains the storage layout for upgradeable modular accounts.
/// @dev `||` for variables in comments refers to the concat operator
contract AccountStorageV1 {
    /// @custom:storage-location erc7201:Alchemy.UpgradeableModularAccount.Storage_V1
    struct AccountStorage {
        // AccountStorageInitializable variables
        uint8 initialized;
        bool initializing;
        // Plugin metadata storage
        LinkedListSet plugins;
        mapping(address => PluginData) pluginData;
        // Execution functions and their associated functions
        mapping(bytes4 => SelectorData) selectorData;
        // bytes24 key = address(calling plugin) || bytes4(selector of execution function)
        mapping(bytes24 => bool) callPermitted;
        // keys = address(calling plugin), target address
        mapping(IPlugin => mapping(address => PermittedExternalCallData)) permittedExternalCalls;
        // For ERC165 introspection, each count indicates support from account or an installed plugin.
        // 0 indicates the account does not support the interface and all plugins that support this interface have
        // been uninstalled.
        mapping(bytes4 => uint256) supportedInterfaces;
    }

    struct PluginData {
        bool anyExternalAddressPermitted;
        // A boolean to indicate if the plugin can spend native tokens, if any of the execution function can spend
        // native tokens, a plugin is considered to be able to spend native tokens of the accounts
        bool canSpendNativeToken;
        bytes32 manifestHash;
        FunctionReference[] dependencies;
        // Tracks the number of times this plugin has been used as a dependency function
        uint256 dependentCount;
    }

    /// @dev Represents data associated with a plugin's permission to use `executeFromPluginExternal` to interact
    /// with contracts and addresses external to the account and its plugins.
    struct PermittedExternalCallData {
        // Is this address on the permitted addresses list? If it is, we either have a
        // list of allowed selectors, or the flag that allows any selector.
        bool addressPermitted;
        bool anySelectorPermitted;
        mapping(bytes4 => bool) permittedSelectors;
    }

    struct HookGroup {
        // NOTE: this uses the flag _PRE_EXEC_HOOK_HAS_POST_FLAG to indicate whether
        // an element has an associated post-exec hook.
        LinkedListSet preHooks;
        // bytes21 key = pre exec hook function reference
        mapping(FunctionReference => LinkedListSet) associatedPostHooks;
        LinkedListSet postOnlyHooks;
    }

    /// @dev Represents data associated with a specifc function selector.
    struct SelectorData {
        // The plugin that implements this execution function.
        // If this is a native function, the address must remain address(0).
        address plugin;
        // Cached flags indicating whether or not this function has pre-execution hooks and
        // post-only hooks. Flags for pre-validation hooks stored in the same storage word
        // as the validation function itself, to use a warm storage slot when loading.
        bool hasPreExecHooks;
        bool hasPostOnlyExecHooks;
        // The specified validation functions for this function selector.
        FunctionReference userOpValidation;
        bool hasPreUserOpValidationHooks;
        FunctionReference runtimeValidation;
        bool hasPreRuntimeValidationHooks;
        // The pre validation hooks for this function selector.
        LinkedListSet preUserOpValidationHooks;
        LinkedListSet preRuntimeValidationHooks;
        // The execution hooks for this function selector.
        HookGroup executionHooks;
    }

    /// @dev the same storage slot will be used versions V1.x.y of upgradeable modular accounts. Follows ERC-7201.
    /// bytes = keccak256(
    ///     abi.encode(uint256(keccak256("Alchemy.UpgradeableModularAccount.Storage_V1")) - 1)
    /// ) & ~bytes32(uint256(0xff));
    /// This cannot be evaluated at compile time because of its use in inline assembly.
    bytes32 internal constant _V1_STORAGE_SLOT = 0xade46bbfcf6f898a43d541e42556d456ca0bf9b326df8debc0f29d3f811a0300;

    function _getAccountStorage() internal pure returns (AccountStorage storage storage_) {
        assembly ("memory-safe") {
            storage_.slot := _V1_STORAGE_SLOT
        }
    }

    function _getPermittedCallKey(address addr, bytes4 selector) internal pure returns (bytes24) {
        return bytes24(bytes20(addr)) | (bytes24(selector) >> 160);
    }
}

// erc6900_smart_contracts_lib/src/account/AccountStorageInitializable.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @title Account Storage Initializable
/// @author Alchemy
/// @notice This enables functions that can be called only once per implementation with the same storage layout
/// @dev Adapted from OpenZeppelin's Initializable and modified to use a diamond storage pattern. Removed
/// Initialized() event since the account already emits an event on initialization.
abstract contract AccountStorageInitializable is AccountStorageV1 {
    error AlreadyInitialized();
    error AlreadyInitializing();

    /// @notice Modifier to put on function intended to be called only once per implementation
    /// @dev Reverts if the contract has already been initialized
    modifier initializer() {
        AccountStorage storage storage_ = _getAccountStorage();
        bool isTopLevelCall = !storage_.initializing;
        if (
            isTopLevelCall && storage_.initialized < 1
                || !Address.isContract(address(this)) && storage_.initialized == 1
        ) {
            storage_.initialized = 1;
            if (isTopLevelCall) {
                storage_.initializing = true;
            }
            _;
            if (isTopLevelCall) {
                storage_.initializing = false;
            }
        } else {
            revert AlreadyInitialized();
        }
    }

    /// @notice Internal function to disable calls to initialization functions
    /// @dev Reverts if the contract has already been initialized
    function _disableInitializers() internal virtual {
        AccountStorage storage storage_ = _getAccountStorage();
        if (storage_.initializing) {
            revert AlreadyInitializing();
        }
        if (storage_.initialized != type(uint8).max) {
            storage_.initialized = type(uint8).max;
        }
    }
}

// erc6900_smart_contracts_lib/src/helpers/KnownSelectors.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @title Known Selectors
/// @author Alchemy
/// @notice Library to help to check if a selector is a know function selector of the modular account or ERC-4337
/// contract.
library KnownSelectors {
    function isNativeFunction(bytes4 selector) internal pure returns (bool) {
        return
        // check against IAccount methods
        selector == IAccount.validateUserOp.selector
        // check against IAccountView methods
        || selector == IAccountView.entryPoint.selector || selector == IAccountView.getNonce.selector
        // check against IPluginManager methods
        || selector == IPluginManager.installPlugin.selector || selector == IPluginManager.uninstallPlugin.selector
        // check against IERC165 methods
        || selector == IERC165.supportsInterface.selector
        // check against UUPSUpgradeable methods
        || selector == UUPSUpgradeable.proxiableUUID.selector
            || selector == UUPSUpgradeable.upgradeToAndCall.selector
        // check against IStandardExecutor methods
        || selector == IStandardExecutor.execute.selector || selector == IStandardExecutor.executeBatch.selector
        // check against IPluginExecutor methods
        || selector == IPluginExecutor.executeFromPlugin.selector
            || selector == IPluginExecutor.executeFromPluginExternal.selector
        // check against IAccountInitializable methods
        || selector == IAccountInitializable.initialize.selector
        // check against IAccountLoupe methods
        || selector == IAccountLoupe.getExecutionFunctionConfig.selector
            || selector == IAccountLoupe.getExecutionHooks.selector
            || selector == IAccountLoupe.getPreValidationHooks.selector
            || selector == IAccountLoupe.getInstalledPlugins.selector
        // check against token receiver methods
        || selector == IERC777Recipient.tokensReceived.selector
            || selector == IERC721Receiver.onERC721Received.selector
            || selector == IERC1155Receiver.onERC1155Received.selector
            || selector == IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function isErc4337Function(bytes4 selector) internal pure returns (bool) {
        return selector == IAggregator.validateSignatures.selector
            || selector == IAggregator.validateUserOpSignature.selector
            || selector == IAggregator.aggregateSignatures.selector
            || selector == IPaymaster.validatePaymasterUserOp.selector || selector == IPaymaster.postOp.selector;
    }

    function isIPluginFunction(bytes4 selector) internal pure returns (bool) {
        return selector == IPlugin.onInstall.selector || selector == IPlugin.onUninstall.selector
            || selector == IPlugin.preUserOpValidationHook.selector
            || selector == IPlugin.userOpValidationFunction.selector
            || selector == IPlugin.preRuntimeValidationHook.selector
            || selector == IPlugin.runtimeValidationFunction.selector || selector == IPlugin.preExecutionHook.selector
            || selector == IPlugin.postExecutionHook.selector || selector == IPlugin.pluginManifest.selector
            || selector == IPlugin.pluginMetadata.selector;
    }
}

// erc6900_smart_contracts_lib/src/account/AccountLoupe.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @title Account Loupe
/// @author Alchemy
/// @notice Provides view functions for querying the configuration of a modular account.
abstract contract AccountLoupe is IAccountLoupe, AccountStorageV1 {
    using LinkedListSetLib for LinkedListSet;
    using CountableLinkedListSetLib for LinkedListSet;

    /// @inheritdoc IAccountLoupe
    function getExecutionFunctionConfig(bytes4 selector)
        external
        view
        returns (ExecutionFunctionConfig memory config)
    {
        AccountStorage storage storage_ = _getAccountStorage();

        if (KnownSelectors.isNativeFunction(selector)) {
            config.plugin = address(this);
        } else {
            config.plugin = storage_.selectorData[selector].plugin;
        }

        config.userOpValidationFunction = storage_.selectorData[selector].userOpValidation;
        config.runtimeValidationFunction = storage_.selectorData[selector].runtimeValidation;
    }

    /// @inheritdoc IAccountLoupe
    function getExecutionHooks(bytes4 selector) external view returns (ExecutionHooks[] memory execHooks) {
        execHooks = _getHooks(_getAccountStorage().selectorData[selector].executionHooks);
    }

    /// @inheritdoc IAccountLoupe
    function getPreValidationHooks(bytes4 selector)
        external
        view
        returns (
            FunctionReference[] memory preUserOpValidationHooks,
            FunctionReference[] memory preRuntimeValidationHooks
        )
    {
        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];
        preUserOpValidationHooks = CastLib.toFunctionReferenceArray(selectorData.preUserOpValidationHooks.getAll());
        preRuntimeValidationHooks =
            CastLib.toFunctionReferenceArray(selectorData.preRuntimeValidationHooks.getAll());
    }

    /// @inheritdoc IAccountLoupe
    function getInstalledPlugins() external view returns (address[] memory pluginAddresses) {
        pluginAddresses = CastLib.toAddressArray(_getAccountStorage().plugins.getAll());
    }

    /// @dev Collects hook data from stored execution hooks and prepares it for returning as the `ExecutionHooks`
    /// type defined by `IAccountLoupe`.
    function _getHooks(HookGroup storage storedHooks) internal view returns (ExecutionHooks[] memory execHooks) {
        FunctionReference[] memory preExecHooks = CastLib.toFunctionReferenceArray(storedHooks.preHooks.getAll());
        FunctionReference[] memory postOnlyExecHooks =
            CastLib.toFunctionReferenceArray(storedHooks.postOnlyHooks.getAll());

        uint256 preExecHooksLength = preExecHooks.length;
        uint256 postOnlyExecHooksLength = postOnlyExecHooks.length;
        uint256 maxExecHooksLength = postOnlyExecHooksLength;

        // There can only be as many associated post hooks to run as there are pre hooks.
        for (uint256 i = 0; i < preExecHooksLength; ++i) {
            unchecked {
                maxExecHooksLength += storedHooks.preHooks.getCount(CastLib.toSetValue(preExecHooks[i]));
            }
        }

        // Overallocate on length - not all of this may get filled up. We set the correct length later.
        execHooks = new ExecutionHooks[](maxExecHooksLength);
        uint256 actualExecHooksLength = 0;

        for (uint256 i = 0; i < preExecHooksLength; ++i) {
            FunctionReference[] memory associatedPostExecHooks =
                CastLib.toFunctionReferenceArray(storedHooks.associatedPostHooks[preExecHooks[i]].getAll());
            uint256 associatedPostExecHooksLength = associatedPostExecHooks.length;

            if (associatedPostExecHooksLength > 0) {
                for (uint256 j = 0; j < associatedPostExecHooksLength; ++j) {
                    execHooks[actualExecHooksLength].preExecHook = preExecHooks[i];
                    execHooks[actualExecHooksLength].postExecHook = associatedPostExecHooks[j];

                    unchecked {
                        ++actualExecHooksLength;
                    }
                }
            } else {
                execHooks[actualExecHooksLength].preExecHook = preExecHooks[i];

                unchecked {
                    ++actualExecHooksLength;
                }
            }
        }

        for (uint256 i = 0; i < postOnlyExecHooksLength; ++i) {
            execHooks[actualExecHooksLength].postExecHook = postOnlyExecHooks[i];

            unchecked {
                ++actualExecHooksLength;
            }
        }

        // "Trim" the exec hooks array to the actual length, since we may have overallocated.
        assembly ("memory-safe") {
            mstore(execHooks, actualExecHooksLength)
        }
    }
}

// erc6900_smart_contracts_lib/src/account/PluginManagerInternals.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @title Plugin Manager Internals
/// @author Alchemy
/// @notice Contains functions to manage the state and behavior of plugin installs and uninstalls.
abstract contract PluginManagerInternals is IPluginManager, AccountStorageV1 {
    using LinkedListSetLib for LinkedListSet;
    using CountableLinkedListSetLib for LinkedListSet;
    using FunctionReferenceLib for FunctionReference;

    // Grouping of arguments to `uninstallPlugin` to avoid "stack too deep"
    // errors when building without via-ir.
    struct UninstallPluginArgs {
        address plugin;
        PluginManifest manifest;
        bool forceUninstall;
        uint256 callbackGasLimit;
    }

    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 internal constant _INVALID_INTERFACE_ID = 0xffffffff;

    // These flags are used in LinkedListSet values to optimize lookups.
    // It's important that they don't overlap with bit 1 and bit 2, which are reserved bits used to indicate
    // the sentinel value and the existence of a next value, respectively.
    uint16 internal constant _PRE_EXEC_HOOK_HAS_POST_FLAG = 0x0004; // bit 3

    error ArrayLengthMismatch();
    error DuplicateHookLimitExceeded(bytes4 selector, FunctionReference hook);
    error DuplicatePreRuntimeValidationHookLimitExceeded(bytes4 selector, FunctionReference hook);
    error DuplicatePreUserOpValidationHookLimitExceeded(bytes4 selector, FunctionReference hook);
    error Erc4337FunctionNotAllowed(bytes4 selector);
    error ExecutionFunctionAlreadySet(bytes4 selector);
    error InterfaceNotAllowed();
    error InvalidDependenciesProvided();
    error InvalidPluginManifest();
    error IPluginFunctionNotAllowed(bytes4 selector);
    error MissingPluginDependency(address dependency);
    error NativeFunctionNotAllowed(bytes4 selector);
    error NullFunctionReference();
    error PluginAlreadyInstalled(address plugin);
    error PluginDependencyViolation(address plugin);
    error PluginInstallCallbackFailed(address plugin, bytes revertReason);
    error PluginInterfaceNotSupported(address plugin);
    error PluginNotInstalled(address plugin);
    error PluginUninstallCallbackFailed(address plugin, bytes revertReason);
    error RuntimeValidationFunctionAlreadySet(bytes4 selector, FunctionReference validationFunction);
    error UserOpValidationFunctionAlreadySet(bytes4 selector, FunctionReference validationFunction);

    // Storage update operations

    function _setExecutionFunction(bytes4 selector, address plugin) internal {
        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];

        if (selectorData.plugin != address(0)) {
            revert ExecutionFunctionAlreadySet(selector);
        }

        // Make sure incoming execution function does not collide with any native functions (data are stored on the
        // account implementation contract)
        if (KnownSelectors.isNativeFunction(selector)) {
            revert NativeFunctionNotAllowed(selector);
        }

        // Make sure incoming execution function is not a function in IPlugin
        if (KnownSelectors.isIPluginFunction(selector)) {
            revert IPluginFunctionNotAllowed(selector);
        }

        // Also make sure it doesn't collide with functions defined by ERC-4337
        // and called by the entry point. This prevents a malicious plugin from
        // sneaking in a function with the same selector as e.g.
        // `validatePaymasterUserOp` and turning the account into their own
        // personal paymaster.
        if (KnownSelectors.isErc4337Function(selector)) {
            revert Erc4337FunctionNotAllowed(selector);
        }

        selectorData.plugin = plugin;
    }

    function _addUserOpValidationFunction(bytes4 selector, FunctionReference validationFunction) internal {
        _assertNotNullFunction(validationFunction);

        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];

        if (!selectorData.userOpValidation.isEmpty()) {
            revert UserOpValidationFunctionAlreadySet(selector, validationFunction);
        }

        selectorData.userOpValidation = validationFunction;
    }

    function _addRuntimeValidationFunction(bytes4 selector, FunctionReference validationFunction) internal {
        _assertNotNullFunction(validationFunction);

        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];

        if (!selectorData.runtimeValidation.isEmpty()) {
            revert RuntimeValidationFunctionAlreadySet(selector, validationFunction);
        }

        selectorData.runtimeValidation = validationFunction;
    }

    function _addExecHooks(bytes4 selector, FunctionReference preExecHook, FunctionReference postExecHook)
        internal
    {
        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];

        _addHooks(selectorData.executionHooks, selector, preExecHook, postExecHook);

        if (!preExecHook.isEmpty()) {
            selectorData.hasPreExecHooks = true;
        } else if (!postExecHook.isEmpty()) {
            // Only set this flag if the pre hook is empty and the post hook is non-empty.
            selectorData.hasPostOnlyExecHooks = true;
        }
    }

    function _removeExecHooks(bytes4 selector, FunctionReference preExecHook, FunctionReference postExecHook)
        internal
    {
        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];

        (bool shouldClearHasPreHooks, bool shouldClearHasPostOnlyHooks) =
            _removeHooks(selectorData.executionHooks, preExecHook, postExecHook);

        if (shouldClearHasPreHooks) {
            selectorData.hasPreExecHooks = false;
        }

        if (shouldClearHasPostOnlyHooks) {
            selectorData.hasPostOnlyExecHooks = false;
        }
    }

    function _addHooks(
        HookGroup storage hooks,
        bytes4 selector,
        FunctionReference preExecHook,
        FunctionReference postExecHook
    ) internal {
        if (!preExecHook.isEmpty()) {
            // add pre or pre/post pair of exec hooks
            if (!hooks.preHooks.tryIncrement(CastLib.toSetValue(preExecHook))) {
                revert DuplicateHookLimitExceeded(selector, preExecHook);
            }

            if (!postExecHook.isEmpty()) {
                // can ignore return val of tryEnableFlags here as tryIncrement above must have succeeded
                hooks.preHooks.tryEnableFlags(CastLib.toSetValue(preExecHook), _PRE_EXEC_HOOK_HAS_POST_FLAG);
                if (!hooks.associatedPostHooks[preExecHook].tryIncrement(CastLib.toSetValue(postExecHook))) {
                    revert DuplicateHookLimitExceeded(selector, postExecHook);
                }
            }
        } else {
            // both pre and post hooks cannot be null
            _assertNotNullFunction(postExecHook);

            if (!hooks.postOnlyHooks.tryIncrement(CastLib.toSetValue(postExecHook))) {
                revert DuplicateHookLimitExceeded(selector, postExecHook);
            }
        }
    }

    function _removeHooks(HookGroup storage hooks, FunctionReference preExecHook, FunctionReference postExecHook)
        internal
        returns (bool shouldClearHasPreHooks, bool shouldClearHasPostOnlyHooks)
    {
        if (!preExecHook.isEmpty()) {
            // If decrementing results in removal, this also clears the flag _PRE_EXEC_HOOK_HAS_POST_FLAG.
            // Can ignore the return value because the manifest was checked to match the hash.
            hooks.preHooks.tryDecrement(CastLib.toSetValue(preExecHook));

            // Update the cached flag value for the pre-exec hooks, as it may change with a removal.
            if (hooks.preHooks.isEmpty()) {
                // The "has pre exec hooks" flag should be disabled
                shouldClearHasPreHooks = true;
            }

            if (!postExecHook.isEmpty()) {
                // Remove the associated post-exec hook, if it is set to the expected value.
                // Can ignore the return value because the manifest was checked to match the hash.
                hooks.associatedPostHooks[preExecHook].tryDecrement(CastLib.toSetValue(postExecHook));

                if (hooks.associatedPostHooks[preExecHook].isEmpty()) {
                    // We can ignore return val of tryDisableFlags here as tryDecrement above must have succeeded
                    // in either removing the element or decrementing its count.
                    hooks.preHooks.tryDisableFlags(CastLib.toSetValue(preExecHook), _PRE_EXEC_HOOK_HAS_POST_FLAG);
                }
            }
        } else {
            // If this else branch is reached, it must be a post-only exec hook, because installation would fail
            // when both the pre and post exec hooks are empty.

            // Can ignore the return value because the manifest was checked to match the hash.
            hooks.postOnlyHooks.tryDecrement(CastLib.toSetValue(postExecHook));

            // Update the cached flag value for the post-only exec hooks, as it may change with a removal.
            if (hooks.postOnlyHooks.isEmpty()) {
                // The "has post only hooks" flag should be disabled
                shouldClearHasPostOnlyHooks = true;
            }
        }
    }

    function _addPreUserOpValidationHook(bytes4 selector, FunctionReference preUserOpValidationHook) internal {
        _assertNotNullFunction(preUserOpValidationHook);

        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];
        if (!selectorData.preUserOpValidationHooks.tryIncrement(CastLib.toSetValue(preUserOpValidationHook))) {
            revert DuplicatePreUserOpValidationHookLimitExceeded(selector, preUserOpValidationHook);
        }
        // add the pre user op validation hook to the cache for the given selector
        if (!selectorData.hasPreUserOpValidationHooks) {
            selectorData.hasPreUserOpValidationHooks = true;
        }
    }

    function _removePreUserOpValidationHook(bytes4 selector, FunctionReference preUserOpValidationHook) internal {
        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];
        // Can ignore the return value because the manifest was checked to match the hash.
        selectorData.preUserOpValidationHooks.tryDecrement(CastLib.toSetValue(preUserOpValidationHook));

        if (selectorData.preUserOpValidationHooks.isEmpty()) {
            selectorData.hasPreUserOpValidationHooks = false;
        }
    }

    function _addPreRuntimeValidationHook(bytes4 selector, FunctionReference preRuntimeValidationHook) internal {
        _assertNotNullFunction(preRuntimeValidationHook);

        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];
        if (!selectorData.preRuntimeValidationHooks.tryIncrement(CastLib.toSetValue(preRuntimeValidationHook))) {
            revert DuplicatePreRuntimeValidationHookLimitExceeded(selector, preRuntimeValidationHook);
        }
        // add the pre runtime validation hook's existence to the validator cache for the given selector
        if (!selectorData.hasPreRuntimeValidationHooks) {
            selectorData.hasPreRuntimeValidationHooks = true;
        }
    }

    function _removePreRuntimeValidationHook(bytes4 selector, FunctionReference preRuntimeValidationHook)
        internal
    {
        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];
        // Can ignore the return value because the manifest was checked to match the hash.
        selectorData.preRuntimeValidationHooks.tryDecrement(CastLib.toSetValue(preRuntimeValidationHook));

        if (selectorData.preRuntimeValidationHooks.isEmpty()) {
            selectorData.hasPreRuntimeValidationHooks = false;
        }
    }

    function _installPlugin(
        address plugin,
        bytes32 manifestHash,
        bytes memory pluginInstallData,
        FunctionReference[] memory dependencies
    ) internal {
        AccountStorage storage storage_ = _getAccountStorage();

        // Check if the plugin exists, also invalidate null address.
        if (!storage_.plugins.tryAdd(CastLib.toSetValue(plugin))) {
            revert PluginAlreadyInstalled(plugin);
        }

        // Check that the plugin supports the IPlugin interface.
        if (!ERC165Checker.supportsInterface(plugin, type(IPlugin).interfaceId)) {
            revert PluginInterfaceNotSupported(plugin);
        }

        // Check manifest hash.
        PluginManifest memory manifest = IPlugin(plugin).pluginManifest();
        if (!_isValidPluginManifest(manifest, manifestHash)) {
            revert InvalidPluginManifest();
        }

        // Check that the dependencies match the manifest.
        uint256 length = dependencies.length;
        if (length != manifest.dependencyInterfaceIds.length) {
            revert InvalidDependenciesProvided();
        }

        for (uint256 i = 0; i < length; ++i) {
            // Check the dependency interface id over the address of the dependency.
            (address dependencyAddr,) = dependencies[i].unpack();

            // Check that the dependency is installed. This also blocks self-dependencies.
            if (storage_.pluginData[dependencyAddr].manifestHash == bytes32(0)) {
                revert MissingPluginDependency(dependencyAddr);
            }

            // Check that the dependency supports the expected interface.
            if (!ERC165Checker.supportsInterface(dependencyAddr, manifest.dependencyInterfaceIds[i])) {
                revert InvalidDependenciesProvided();
            }

            // Increment the dependency's dependents counter.
            storage_.pluginData[dependencyAddr].dependentCount += 1;
        }

        // Update components according to the manifest.

        // Install execution functions
        length = manifest.executionFunctions.length;
        for (uint256 i = 0; i < length; ++i) {
            _setExecutionFunction(manifest.executionFunctions[i], plugin);
        }

        // Add installed plugin and selectors this plugin can call
        length = manifest.permittedExecutionSelectors.length;
        for (uint256 i = 0; i < length; ++i) {
            storage_.callPermitted[_getPermittedCallKey(plugin, manifest.permittedExecutionSelectors[i])] = true;
        }

        // Add the permitted external calls to the account.
        if (manifest.permitAnyExternalAddress) {
            storage_.pluginData[plugin].anyExternalAddressPermitted = true;
        } else {
            // Only store the specific permitted external calls if "permit any" flag was not set.
            length = manifest.permittedExternalCalls.length;
            for (uint256 i = 0; i < length; ++i) {
                ManifestExternalCallPermission memory externalCallPermission = manifest.permittedExternalCalls[i];

                PermittedExternalCallData storage permittedExternalCallData =
                    storage_.permittedExternalCalls[IPlugin(plugin)][externalCallPermission.externalAddress];

                permittedExternalCallData.addressPermitted = true;

                if (externalCallPermission.permitAnySelector) {
                    permittedExternalCallData.anySelectorPermitted = true;
                } else {
                    uint256 externalContractSelectorsLength = externalCallPermission.selectors.length;
                    for (uint256 j = 0; j < externalContractSelectorsLength; ++j) {
                        permittedExternalCallData.permittedSelectors[externalCallPermission.selectors[j]] = true;
                    }
                }
            }
        }

        // Add user operation validation functions
        length = manifest.userOpValidationFunctions.length;
        for (uint256 i = 0; i < length; ++i) {
            ManifestAssociatedFunction memory mv = manifest.userOpValidationFunctions[i];
            _addUserOpValidationFunction(
                mv.executionSelector,
                _resolveManifestFunction(
                    mv.associatedFunction, plugin, dependencies, ManifestAssociatedFunctionType.NONE
                )
            );
        }

        // Add runtime validation functions
        length = manifest.runtimeValidationFunctions.length;
        for (uint256 i = 0; i < length; ++i) {
            ManifestAssociatedFunction memory mv = manifest.runtimeValidationFunctions[i];
            _addRuntimeValidationFunction(
                mv.executionSelector,
                _resolveManifestFunction(
                    mv.associatedFunction,
                    plugin,
                    dependencies,
                    ManifestAssociatedFunctionType.RUNTIME_VALIDATION_ALWAYS_ALLOW
                )
            );
        }

        // Passed to _resolveManifestFunction when DEPENDENCY is not a valid function type.
        FunctionReference[] memory noDependencies = new FunctionReference[](0);

        // Add pre user operation validation hooks
        length = manifest.preUserOpValidationHooks.length;
        for (uint256 i = 0; i < length; ++i) {
            ManifestAssociatedFunction memory mh = manifest.preUserOpValidationHooks[i];
            _addPreUserOpValidationHook(
                mh.executionSelector,
                _resolveManifestFunction(
                    mh.associatedFunction,
                    plugin,
                    noDependencies,
                    ManifestAssociatedFunctionType.PRE_HOOK_ALWAYS_DENY
                )
            );
        }

        // Add pre runtime validation hooks
        length = manifest.preRuntimeValidationHooks.length;
        for (uint256 i = 0; i < length; ++i) {
            ManifestAssociatedFunction memory mh = manifest.preRuntimeValidationHooks[i];
            _addPreRuntimeValidationHook(
                mh.executionSelector,
                _resolveManifestFunction(
                    mh.associatedFunction,
                    plugin,
                    noDependencies,
                    ManifestAssociatedFunctionType.PRE_HOOK_ALWAYS_DENY
                )
            );
        }

        // Add pre and post execution hooks
        length = manifest.executionHooks.length;
        for (uint256 i = 0; i < length; ++i) {
            ManifestExecutionHook memory mh = manifest.executionHooks[i];
            _addExecHooks(
                mh.executionSelector,
                _resolveManifestFunction(
                    mh.preExecHook, plugin, noDependencies, ManifestAssociatedFunctionType.PRE_HOOK_ALWAYS_DENY
                ),
                _resolveManifestFunction(
                    mh.postExecHook, plugin, noDependencies, ManifestAssociatedFunctionType.NONE
                )
            );
        }

        // Add new interface ids the plugin enabled for the account
        length = manifest.interfaceIds.length;
        for (uint256 i = 0; i < length; ++i) {
            bytes4 interfaceId = manifest.interfaceIds[i];
            if (interfaceId == type(IPlugin).interfaceId || interfaceId == _INVALID_INTERFACE_ID) {
                revert InterfaceNotAllowed();
            }
            storage_.supportedInterfaces[interfaceId] += 1;
        }

        // Add the plugin metadata to the account
        storage_.pluginData[plugin].manifestHash = manifestHash;
        storage_.pluginData[plugin].dependencies = dependencies;

        // Mark whether or not this plugin may spend native token amounts
        if (manifest.canSpendNativeToken) {
            storage_.pluginData[plugin].canSpendNativeToken = true;
        }

        // Initialize the plugin storage for the account.
        // solhint-disable-next-line no-empty-blocks
        try IPlugin(plugin).onInstall(pluginInstallData) {}
        catch (bytes memory revertReason) {
            revert PluginInstallCallbackFailed(plugin, revertReason);
        }

        emit PluginInstalled(plugin, manifestHash, dependencies);
    }

    function _uninstallPlugin(UninstallPluginArgs memory args, bytes calldata pluginUninstallData) internal {
        AccountStorage storage storage_ = _getAccountStorage();

        // Check if the plugin exists.
        if (!storage_.plugins.tryRemove(CastLib.toSetValue(args.plugin))) {
            revert PluginNotInstalled(args.plugin);
        }

        PluginData memory pluginData = storage_.pluginData[args.plugin];

        // Check manifest hash.
        if (!_isValidPluginManifest(args.manifest, pluginData.manifestHash)) {
            revert InvalidPluginManifest();
        }

        // Ensure that there are no dependent plugins.
        if (pluginData.dependentCount != 0) {
            revert PluginDependencyViolation(args.plugin);
        }

        // Remove this plugin as a dependent from its dependencies.
        FunctionReference[] memory dependencies = pluginData.dependencies;
        uint256 length = dependencies.length;
        for (uint256 i = 0; i < length; ++i) {
            FunctionReference dependency = dependencies[i];
            (address dependencyAddr,) = dependency.unpack();

            // Decrement the dependent count for the dependency function.
            storage_.pluginData[dependencyAddr].dependentCount -= 1;
        }

        // Remove the plugin metadata from the account.
        delete storage_.pluginData[args.plugin];

        // Remove components according to the manifest, in reverse order (by component type) of their installation.

        // Passed to _resolveManifestFunction when DEPENDENCY is not a valid function type.
        FunctionReference[] memory noDependencies = new FunctionReference[](0);

        // Remove pre and post execution function hooks
        length = args.manifest.executionHooks.length;
        for (uint256 i = 0; i < length; ++i) {
            ManifestExecutionHook memory mh = args.manifest.executionHooks[i];
            _removeExecHooks(
                mh.executionSelector,
                _resolveManifestFunction(
                    mh.preExecHook,
                    args.plugin,
                    noDependencies,
                    ManifestAssociatedFunctionType.PRE_HOOK_ALWAYS_DENY
                ),
                _resolveManifestFunction(
                    mh.postExecHook, args.plugin, noDependencies, ManifestAssociatedFunctionType.NONE
                )
            );
        }

        // Remove pre runtime validation function hooks
        length = args.manifest.preRuntimeValidationHooks.length;
        for (uint256 i = 0; i < length; ++i) {
            ManifestAssociatedFunction memory mh = args.manifest.preRuntimeValidationHooks[i];

            _removePreRuntimeValidationHook(
                mh.executionSelector,
                _resolveManifestFunction(
                    mh.associatedFunction,
                    args.plugin,
                    noDependencies,
                    ManifestAssociatedFunctionType.PRE_HOOK_ALWAYS_DENY
                )
            );
        }

        // Remove pre user op validation function hooks
        length = args.manifest.preUserOpValidationHooks.length;
        for (uint256 i = 0; i < length; ++i) {
            ManifestAssociatedFunction memory mh = args.manifest.preUserOpValidationHooks[i];

            _removePreUserOpValidationHook(
                mh.executionSelector,
                _resolveManifestFunction(
                    mh.associatedFunction,
                    args.plugin,
                    noDependencies,
                    ManifestAssociatedFunctionType.PRE_HOOK_ALWAYS_DENY
                )
            );
        }

        // Remove runtime validation function hooks
        length = args.manifest.runtimeValidationFunctions.length;
        for (uint256 i = 0; i < length; ++i) {
            bytes4 executionSelector = args.manifest.runtimeValidationFunctions[i].executionSelector;
            storage_.selectorData[executionSelector].runtimeValidation =
                FunctionReferenceLib._EMPTY_FUNCTION_REFERENCE;
        }

        // Remove user op validation function hooks
        length = args.manifest.userOpValidationFunctions.length;
        for (uint256 i = 0; i < length; ++i) {
            bytes4 executionSelector = args.manifest.userOpValidationFunctions[i].executionSelector;
            storage_.selectorData[executionSelector].userOpValidation =
                FunctionReferenceLib._EMPTY_FUNCTION_REFERENCE;
        }

        // Remove permitted external call permissions, anyExternalAddressPermitted is cleared when pluginData being
        // deleted
        if (!args.manifest.permitAnyExternalAddress) {
            // Only clear the specific permitted external calls if "permit any" flag was not set.
            length = args.manifest.permittedExternalCalls.length;
            for (uint256 i = 0; i < length; ++i) {
                ManifestExternalCallPermission memory externalCallPermission =
                    args.manifest.permittedExternalCalls[i];

                PermittedExternalCallData storage permittedExternalCallData =
                    storage_.permittedExternalCalls[IPlugin(args.plugin)][externalCallPermission.externalAddress];

                permittedExternalCallData.addressPermitted = false;

                // Only clear this flag if it was set in the constructor.
                if (externalCallPermission.permitAnySelector) {
                    permittedExternalCallData.anySelectorPermitted = false;
                } else {
                    uint256 externalContractSelectorsLength = externalCallPermission.selectors.length;
                    for (uint256 j = 0; j < externalContractSelectorsLength; ++j) {
                        permittedExternalCallData.permittedSelectors[externalCallPermission.selectors[j]] = false;
                    }
                }
            }
        }

        // Remove permitted account execution function call permissions
        length = args.manifest.permittedExecutionSelectors.length;
        for (uint256 i = 0; i < length; ++i) {
            storage_.callPermitted[_getPermittedCallKey(args.plugin, args.manifest.permittedExecutionSelectors[i])]
            = false;
        }

        // Remove installed execution function
        length = args.manifest.executionFunctions.length;
        for (uint256 i = 0; i < length; ++i) {
            storage_.selectorData[args.manifest.executionFunctions[i]].plugin = address(0);
        }

        // Decrease supported interface ids' counters
        length = args.manifest.interfaceIds.length;
        for (uint256 i = 0; i < length; ++i) {
            storage_.supportedInterfaces[args.manifest.interfaceIds[i]] -= 1;
        }

        // Clear the plugin storage for the account.
        bool onUninstallSucceeded = true;
        // solhint-disable-next-line no-empty-blocks
        try IPlugin(args.plugin).onUninstall{gas: args.callbackGasLimit}(pluginUninstallData) {}
        catch (bytes memory revertReason) {
            if (!args.forceUninstall) {
                revert PluginUninstallCallbackFailed(args.plugin, revertReason);
            }
            onUninstallSucceeded = false;
        }

        emit PluginUninstalled(args.plugin, onUninstallSucceeded);
    }

    function _isValidPluginManifest(PluginManifest memory manifest, bytes32 manifestHash)
        internal
        pure
        returns (bool)
    {
        return manifestHash == keccak256(abi.encode(manifest));
    }

    function _resolveManifestFunction(
        ManifestFunction memory manifestFunction,
        address plugin,
        // Can be empty to indicate that type DEPENDENCY is invalid for this function.
        FunctionReference[] memory dependencies,
        // Indicates which magic value, if any, is permissible for the function to resolve.
        ManifestAssociatedFunctionType allowedMagicValue
    ) internal pure returns (FunctionReference) {
        if (manifestFunction.functionType == ManifestAssociatedFunctionType.SELF) {
            return FunctionReferenceLib.pack(plugin, manifestFunction.functionId);
        }
        if (manifestFunction.functionType == ManifestAssociatedFunctionType.DEPENDENCY) {
            uint256 index = manifestFunction.dependencyIndex;
            if (index < dependencies.length) {
                return dependencies[index];
            }
            revert InvalidPluginManifest();
        }
        if (manifestFunction.functionType == ManifestAssociatedFunctionType.RUNTIME_VALIDATION_ALWAYS_ALLOW) {
            if (allowedMagicValue == ManifestAssociatedFunctionType.RUNTIME_VALIDATION_ALWAYS_ALLOW) {
                return FunctionReferenceLib._RUNTIME_VALIDATION_ALWAYS_ALLOW;
            }
            revert InvalidPluginManifest();
        }
        if (manifestFunction.functionType == ManifestAssociatedFunctionType.PRE_HOOK_ALWAYS_DENY) {
            if (allowedMagicValue == ManifestAssociatedFunctionType.PRE_HOOK_ALWAYS_DENY) {
                return FunctionReferenceLib._PRE_HOOK_ALWAYS_DENY;
            }
            revert InvalidPluginManifest();
        }
        return FunctionReferenceLib._EMPTY_FUNCTION_REFERENCE; // Empty checks are done elsewhere
    }

    function _assertNotNullFunction(FunctionReference functionReference) internal pure {
        if (functionReference.isEmpty()) {
            revert NullFunctionReference();
        }
    }
}

// erc6900_smart_contracts_lib/src/account/UpgradeableModularAccount.sol
// This file is part of Modular Account.
//
// Copyright 2024 Alchemy Insights, Inc.
//

//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General
// Public License as published by the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
// implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with this program. If not, see
// <https://www.gnu.org/licenses/>.

/// @title Upgradeable Modular Account
/// @author Alchemy
/// @notice A modular smart contract account (MSCA) that supports upgradeability and plugins.
contract UpgradeableModularAccount is
    AccountExecutor,
    AccountLoupe,
    AccountStorageInitializable,
    PluginManagerInternals,
    IAccount,
    IAccountInitializable,
    IAccountView,
    IERC165,
    IERC721Receiver,
    IERC777Recipient,
    IERC1155Receiver,
    IPluginExecutor,
    IStandardExecutor,
    UUPSUpgradeable
{
    using CountableLinkedListSetLib for LinkedListSet;
    using LinkedListSetLib for LinkedListSet;
    using FunctionReferenceLib for FunctionReference;

    /// @dev Struct to hold optional configuration data for uninstalling a plugin. This should be encoded and
    /// passed to the `config` parameter of `uninstallPlugin`.
    struct UninstallPluginConfig {
        // ABI-encoding of a `PluginManifest` to specify the original manifest
        // used to install the plugin now being uninstalled, in cases where the
        // plugin manifest has changed. If empty, uses the default behavior of
        // calling the plugin to get its current manifest.
        bytes serializedManifest;
        // If true, will complete the uninstall even if the `onUninstall` callback reverts. Available as an escape
        // hatch if a plugin is blocking uninstall.
        bool forceUninstall;
        // Maximum amount of gas allowed for each uninstall callback function
        // (`onUninstall`), or zero to set no limit. Should
        // typically be used with `forceUninstall` to remove plugins that are
        // preventing uninstallation by consuming all remaining gas.
        uint256 callbackGasLimit;
    }

    // ERC-4337 v0.6.0 entrypoint address only
    IEntryPoint private immutable _ENTRY_POINT;

    bytes4 internal constant _IERC165_INTERFACE_ID = 0x01ffc9a7;

    event ModularAccountInitialized(IEntryPoint indexed entryPoint);

    error AlwaysDenyRule();
    error ExecFromPluginNotPermitted(address plugin, bytes4 selector);
    error ExecFromPluginExternalNotPermitted(address plugin, address target, uint256 value, bytes data);
    error NativeTokenSpendingNotPermitted(address plugin);
    error PostExecHookReverted(address plugin, uint8 functionId, bytes revertReason);
    error PreExecHookReverted(address plugin, uint8 functionId, bytes revertReason);
    error PreRuntimeValidationHookFailed(address plugin, uint8 functionId, bytes revertReason);
    error RuntimeValidationFunctionMissing(bytes4 selector);
    error RuntimeValidationFunctionReverted(address plugin, uint8 functionId, bytes revertReason);
    error UnexpectedAggregator(address plugin, uint8 functionId, address aggregator);
    error UnrecognizedFunction(bytes4 selector);
    error UserOpNotFromEntryPoint();
    error UserOpValidationFunctionMissing(bytes4 selector);

    constructor(IEntryPoint anEntryPoint) {
        _ENTRY_POINT = anEntryPoint;
        _disableInitializers();
    }

    // EXTERNAL FUNCTIONS

    /// @inheritdoc IAccountInitializable
    function initialize(address[] calldata plugins, bytes calldata pluginInitData) external initializer {
        (bytes32[] memory manifestHashes, bytes[] memory pluginInstallDatas) =
            abi.decode(pluginInitData, (bytes32[], bytes[]));

        uint256 length = plugins.length;

        if (length != manifestHashes.length || length != pluginInstallDatas.length) {
            revert ArrayLengthMismatch();
        }

        FunctionReference[] memory emptyDependencies = new FunctionReference[](0);

        for (uint256 i = 0; i < length; ++i) {
            _installPlugin(plugins[i], manifestHashes[i], pluginInstallDatas[i], emptyDependencies);
        }

        emit ModularAccountInitialized(_ENTRY_POINT);
    }

    receive() external payable {}

    /// @notice Fallback function that routes calls to plugin execution functions.
    /// @dev We route calls to execution functions based on incoming msg.sig. If there's no plugin associated with
    /// this function selector, revert.
    /// @return Data returned from the called execution function.
    fallback(bytes calldata) external payable returns (bytes memory) {
        // Either reuse the call buffer from runtime validation, or allocate a new one. It may or may not be used
        // for pre exec hooks but it will be used for the plugin execution itself.
        bytes memory callBuffer =
            (msg.sender != address(_ENTRY_POINT)) ? _doRuntimeValidation() : _allocateRuntimeCallBuffer(msg.data);

        // To comply with ERC-6900 phase rules, defer the loading of execution phase data until the completion of
        // runtime validation.
        // Validation may update account state and therefore change execution phase data. These values should also
        // be loaded before
        // we run the pre exec hooks, because they may modify which plugin is defined.
        SelectorData storage selectorData = _getAccountStorage().selectorData[msg.sig];
        address execPlugin = selectorData.plugin;
        if (execPlugin == address(0)) {
            revert UnrecognizedFunction(msg.sig);
        }

        (FunctionReference[][] memory postHooksToRun, bytes[] memory postHookArgs) =
            _doPreExecHooks(selectorData, callBuffer);

        // execute the function, bubbling up any reverts
        bool execSuccess = _executeRaw(execPlugin, _convertRuntimeCallBufferToExecBuffer(callBuffer));
        bytes memory returnData = _collectReturnData();

        if (!execSuccess) {
            // Bubble up revert reasons from plugins
            assembly ("memory-safe") {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        _doCachedPostHooks(postHooksToRun, postHookArgs);

        return returnData;
    }

    /// @inheritdoc IAccount
    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        virtual
        override
        returns (uint256 validationData)
    {
        if (msg.sender != address(_ENTRY_POINT)) {
            revert UserOpNotFromEntryPoint();
        }

        bytes4 selector = _selectorFromCallData(userOp.callData);
        SelectorData storage selectorData = _getAccountStorage().selectorData[selector];

        FunctionReference userOpValidationFunction = selectorData.userOpValidation;
        bool hasPreValidationHooks = selectorData.hasPreUserOpValidationHooks;

        validationData =
            _doUserOpValidation(selector, userOpValidationFunction, userOp, userOpHash, hasPreValidationHooks);

        if (missingAccountFunds != 0) {
            // entry point verifies if call succeeds so we don't need to do here
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            (success);
        }
    }

    /// @inheritdoc IStandardExecutor
    function execute(address target, uint256 value, bytes calldata data)
        external
        payable
        override
        returns (bytes memory result)
    {
        (FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs) = _preNativeFunction();
        result = _exec(target, value, data);
        _postNativeFunction(postExecHooks, postHookArgs);
    }

    /// @inheritdoc IStandardExecutor
    function executeBatch(Call[] calldata calls) external payable override returns (bytes[] memory results) {
        (FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs) = _preNativeFunction();

        uint256 callsLength = calls.length;
        results = new bytes[](callsLength);

        for (uint256 i = 0; i < callsLength; ++i) {
            results[i] = _exec(calls[i].target, calls[i].value, calls[i].data);
        }

        _postNativeFunction(postExecHooks, postHookArgs);
    }

    /// @inheritdoc IPluginExecutor
    function executeFromPlugin(bytes calldata data) external payable override returns (bytes memory returnData) {
        bytes4 selector = _selectorFromCallData(data);
        bytes24 permittedCallKey = _getPermittedCallKey(msg.sender, selector);

        AccountStorage storage storage_ = _getAccountStorage();

        if (!storage_.callPermitted[permittedCallKey]) {
            revert ExecFromPluginNotPermitted(msg.sender, selector);
        }

        bytes memory callBuffer = _allocateRuntimeCallBuffer(data);

        SelectorData storage selectorData = storage_.selectorData[selector];
        // Load the plugin address from storage prior to running any hooks, to abide by the ERC-6900 phase rules.
        address execFunctionPlugin = selectorData.plugin;

        (FunctionReference[][] memory postHooksToRun, bytes[] memory postHookArgs) =
            _doPreExecHooks(selectorData, callBuffer);

        if (execFunctionPlugin == address(0)) {
            revert UnrecognizedFunction(selector);
        }

        bool execSuccess = _executeRaw(execFunctionPlugin, _convertRuntimeCallBufferToExecBuffer(callBuffer));
        returnData = _collectReturnData();

        if (!execSuccess) {
            assembly ("memory-safe") {
                revert(add(returnData, 32), mload(returnData))
            }
        }

        _doCachedPostHooks(postHooksToRun, postHookArgs);

        return returnData;
    }

    /// @inheritdoc IPluginExecutor
    function executeFromPluginExternal(address target, uint256 value, bytes calldata data)
        external
        payable
        returns (bytes memory)
    {
        AccountStorage storage storage_ = _getAccountStorage();
        address callingPlugin = msg.sender;

        // Make sure plugin is allowed to spend native token.
        if (value > 0 && value > msg.value && !storage_.pluginData[callingPlugin].canSpendNativeToken) {
            revert NativeTokenSpendingNotPermitted(callingPlugin);
        }

        // Target cannot be the account itself.
        if (target == address(this)) {
            revert ExecFromPluginExternalNotPermitted(callingPlugin, target, value, data);
        }

        // Check the caller plugin's permission to make this call on the target address.
        //
        // 1. Check that the target is permitted at all, and if so check that any one of the following is true:
        //   a. Is any selector permitted?
        //   b. Is the calldata empty? (allow empty data calls by default if the target address is permitted)
        //   c. Is the selector in the call permitted?
        // 2. If the target is not permitted, instead check whether all external calls are permitted.
        //
        // `addressPermitted` can only be true if `anyExternalAddressPermitted` is false, so we can reduce our
        // worst-case `sloads` by 1 by not checking `anyExternalAddressPermitted` if `addressPermitted` is true.
        //
        // We allow calls where the data may be less than 4 bytes - it's up to the calling contract to
        // determine how to handle this.

        PermittedExternalCallData storage permittedExternalCallData =
            storage_.permittedExternalCalls[IPlugin(callingPlugin)][target];

        bool isTargetCallPermitted;
        if (permittedExternalCallData.addressPermitted) {
            isTargetCallPermitted = (
                permittedExternalCallData.anySelectorPermitted || data.length == 0
                    || permittedExternalCallData.permittedSelectors[bytes4(data)]
            );
        } else {
            isTargetCallPermitted = storage_.pluginData[callingPlugin].anyExternalAddressPermitted;
        }

        // If the target is not permitted, check if the caller plugin is permitted to make any external calls.
        if (!isTargetCallPermitted) {
            revert ExecFromPluginExternalNotPermitted(callingPlugin, target, value, data);
        }

        // Run any pre exec hooks for the `executeFromPluginExternal` selector
        SelectorData storage selectorData =
            storage_.selectorData[IPluginExecutor.executeFromPluginExternal.selector];

        (FunctionReference[][] memory postHooksToRun, bytes[] memory postHookArgs) =
            _doPreExecHooks(selectorData, "");

        // Perform the external call
        bytes memory returnData = _exec(target, value, data);

        _doCachedPostHooks(postHooksToRun, postHookArgs);

        return returnData;
    }

    /// @inheritdoc IPluginManager
    function installPlugin(
        address plugin,
        bytes32 manifestHash,
        bytes calldata pluginInstallData,
        FunctionReference[] calldata dependencies
    ) external override {
        (FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs) = _preNativeFunction();
        _installPlugin(plugin, manifestHash, pluginInstallData, dependencies);
        _postNativeFunction(postExecHooks, postHookArgs);
    }

    /// @inheritdoc IPluginManager
    function uninstallPlugin(address plugin, bytes calldata config, bytes calldata pluginUninstallData)
        external
        override
    {
        (FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs) = _preNativeFunction();

        UninstallPluginArgs memory args;
        args.plugin = plugin;
        bool hasSetManifest;

        if (config.length > 0) {
            UninstallPluginConfig memory decodedConfig = abi.decode(config, (UninstallPluginConfig));
            if (decodedConfig.serializedManifest.length > 0) {
                args.manifest = abi.decode(decodedConfig.serializedManifest, (PluginManifest));
                hasSetManifest = true;
            }
            args.forceUninstall = decodedConfig.forceUninstall;
            args.callbackGasLimit = decodedConfig.callbackGasLimit;
        }
        if (!hasSetManifest) {
            args.manifest = IPlugin(plugin).pluginManifest();
        }
        if (args.callbackGasLimit == 0) {
            args.callbackGasLimit = type(uint256).max;
        }

        _uninstallPlugin(args, pluginUninstallData);

        _postNativeFunction(postExecHooks, postHookArgs);
    }

    /// @inheritdoc IERC777Recipient
    /// @dev Runtime validation is bypassed for this function, but we still allow pre and post exec hooks to be
    /// assigned and run.
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        (FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs) =
            _doPreExecHooks(_getAccountStorage().selectorData[msg.sig], "");
        _tokensReceived(operator, from, to, amount, userData, operatorData);
        _postNativeFunction(postExecHooks, postHookArgs);
    }

    /// @inheritdoc IERC721Receiver
    /// @dev Runtime validation is bypassed for this function, but we still allow pre and post exec hooks to be
    /// assigned and run.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        override
        returns (bytes4 selector)
    {
        (FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs) =
            _doPreExecHooks(_getAccountStorage().selectorData[msg.sig], "");
        selector = _onERC721Received(operator, from, tokenId, data);
        _postNativeFunction(postExecHooks, postHookArgs);
    }

    /// @inheritdoc IERC1155Receiver
    /// @dev Runtime validation is bypassed for this function, but we still allow pre and post exec hooks to be
    /// assigned and run.
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)
        external
        override
        returns (bytes4 selector)
    {
        (FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs) =
            _doPreExecHooks(_getAccountStorage().selectorData[msg.sig], "");
        selector = _onERC1155Received(operator, from, id, value, data);
        _postNativeFunction(postExecHooks, postHookArgs);
    }

    /// @inheritdoc IERC1155Receiver
    /// @dev Runtime validation is bypassed for this function, but we still allow pre and post exec hooks to be
    /// assigned and run.
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4 selector) {
        (FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs) =
            _doPreExecHooks(_getAccountStorage().selectorData[msg.sig], "");
        selector = _onERC1155BatchReceived(operator, from, ids, values, data);
        _postNativeFunction(postExecHooks, postHookArgs);
    }

    /// @inheritdoc UUPSUpgradeable
    function upgradeToAndCall(address newImplementation, bytes calldata data) public payable override onlyProxy {
        (FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs) = _preNativeFunction();
        UUPSUpgradeable.upgradeToAndCall(newImplementation, data);
        _postNativeFunction(postExecHooks, postHookArgs);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        if (interfaceId == _INVALID_INTERFACE_ID) {
            return false;
        }
        return interfaceId == _IERC165_INTERFACE_ID || interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC777Recipient).interfaceId || interfaceId == type(IERC1155Receiver).interfaceId
            || _getAccountStorage().supportedInterfaces[interfaceId] > 0;
    }

    /// @inheritdoc IAccountView
    function entryPoint() public view override returns (IEntryPoint) {
        return _ENTRY_POINT;
    }

    /// @inheritdoc IAccountView
    function getNonce() public view virtual override returns (uint256) {
        return _ENTRY_POINT.getNonce(address(this), 0);
    }

    // INTERNAL FUNCTIONS

    /// @dev Wraps execution of a native function with runtime validation and hooks. Used for upgradeToAndCall,
    /// execute, executeBatch, installPlugin, uninstallPlugin.
    function _preNativeFunction()
        internal
        returns (FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs)
    {
        bytes memory callBuffer = "";

        if (msg.sender != address(_ENTRY_POINT)) {
            callBuffer = _doRuntimeValidation();
        }

        (postExecHooks, postHookArgs) = _doPreExecHooks(_getAccountStorage().selectorData[msg.sig], callBuffer);
    }

    /// @dev Wraps execution of a native function with runtime validation and hooks. Used for upgradeToAndCall,
    /// execute, executeBatch, installPlugin, uninstallPlugin, and the token receiver functions.
    function _postNativeFunction(FunctionReference[][] memory postExecHooks, bytes[] memory postHookArgs)
        internal
    {
        _doCachedPostHooks(postExecHooks, postHookArgs);
    }

    /// @dev To support gas estimation, we don't fail early when the failure is caused by a signature failure.
    function _doUserOpValidation(
        bytes4 selector,
        FunctionReference userOpValidationFunction,
        UserOperation calldata userOp,
        bytes32 userOpHash,
        bool doPreValidationHooks
    ) internal returns (uint256 validationData) {
        if (userOpValidationFunction.isEmpty()) {
            revert UserOpValidationFunctionMissing(selector);
        }

        bytes memory callBuffer =
            _allocateUserOpCallBuffer(IPlugin.preUserOpValidationHook.selector, userOp, userOpHash);

        uint256 currentValidationData;
        uint256 preUserOpValidationHooksLength;

        if (doPreValidationHooks) {
            // Do preUserOpValidation hooks
            FunctionReference[] memory preUserOpValidationHooks = CastLib.toFunctionReferenceArray(
                _getAccountStorage().selectorData[selector].preUserOpValidationHooks.getAll()
            );

            preUserOpValidationHooksLength = preUserOpValidationHooks.length;
            for (uint256 i = 0; i < preUserOpValidationHooksLength; ++i) {
                // FunctionReference preUserOpValidationHook = preUserOpValidationHooks[i];

                if (preUserOpValidationHooks[i].isEmptyOrMagicValue()) {
                    // Empty function reference is impossible here due to the element coming from a LinkedListSet.
                    // Runtime Validation Always Allow is not assignable here.
                    // Pre Hook Always Deny is the only assignable magic value here.
                    revert AlwaysDenyRule();
                }

                (address plugin, uint8 functionId) = preUserOpValidationHooks[i].unpack();

                _updatePluginCallBufferFunctionId(callBuffer, functionId);

                currentValidationData = _executeUserOpPluginFunction(callBuffer, plugin);

                if (uint160(currentValidationData) > 1) {
                    // If the aggregator is not 0 or 1, it is an unexpected value
                    revert UnexpectedAggregator(plugin, functionId, address(uint160(currentValidationData)));
                }
                validationData = _coalescePreValidation(validationData, currentValidationData);
            }
        }

        // Run the user op validation function
        {
            _updatePluginCallBufferSelector(callBuffer, IPlugin.userOpValidationFunction.selector);
            // No magic values are assignable here, and we already checked whether or not the function was empty,
            // so we're OK to use the function immediately
            (address plugin, uint8 functionId) = userOpValidationFunction.unpack();

            _updatePluginCallBufferFunctionId(callBuffer, functionId);

            currentValidationData = _executeUserOpPluginFunction(callBuffer, plugin);

            if (preUserOpValidationHooksLength != 0) {
                // If we have other validation data we need to coalesce with
                validationData = _coalesceValidation(validationData, currentValidationData);
            } else {
                validationData = currentValidationData;
            }
        }
    }

    function _doRuntimeValidation() internal returns (bytes memory callBuffer) {
        AccountStorage storage storage_ = _getAccountStorage();
        FunctionReference runtimeValidationFunction = storage_.selectorData[msg.sig].runtimeValidation;
        bool doPreRuntimeValidationHooks = storage_.selectorData[msg.sig].hasPreRuntimeValidationHooks;

        // Allocate the call buffer for preRuntimeValidationHook
        callBuffer = _allocateRuntimeCallBuffer(msg.data);

        if (doPreRuntimeValidationHooks) {
            _updatePluginCallBufferSelector(callBuffer, IPlugin.preRuntimeValidationHook.selector);

            // run all preRuntimeValidation hooks
            FunctionReference[] memory preRuntimeValidationHooks = CastLib.toFunctionReferenceArray(
                _getAccountStorage().selectorData[msg.sig].preRuntimeValidationHooks.getAll()
            );

            uint256 preRuntimeValidationHooksLength = preRuntimeValidationHooks.length;
            for (uint256 i = 0; i < preRuntimeValidationHooksLength; ++i) {
                FunctionReference preRuntimeValidationHook = preRuntimeValidationHooks[i];

                if (preRuntimeValidationHook.isEmptyOrMagicValue()) {
                    // The function reference must be the Always Deny magic value in this case,
                    // because zero and any other magic value is unassignable here.
                    revert AlwaysDenyRule();
                }

                (address plugin, uint8 functionId) = preRuntimeValidationHook.unpack();

                _updatePluginCallBufferFunctionId(callBuffer, functionId);

                _executeRuntimePluginFunction(callBuffer, plugin, PreRuntimeValidationHookFailed.selector);
            }
        }

        // Identifier scope limiting
        {
            if (runtimeValidationFunction.isEmptyOrMagicValue()) {
                if (
                    runtimeValidationFunction.isEmpty()
                        && (
                            (
                                msg.sig != IPluginManager.installPlugin.selector
                                    && msg.sig != UUPSUpgradeable.upgradeToAndCall.selector
                            ) || msg.sender != address(this)
                        )
                ) {
                    // Runtime calls cannot be made against functions with no
                    // validator, except in the special case of self-calls to
                    // `installPlugin` and `upgradeToAndCall`, to enable removing the plugin protecting
                    // `installPlugin` and installing a different one as part of
                    // a single batch execution, and/or to enable upgrading the account implementation.
                    revert RuntimeValidationFunctionMissing(msg.sig);
                }
                // If _RUNTIME_VALIDATION_ALWAYS_ALLOW, or we're in the
                // `installPlugin` and `upgradeToAndCall` special case,just let the function finish,
                // without the else branch.
            } else {
                _updatePluginCallBufferSelector(callBuffer, IPlugin.runtimeValidationFunction.selector);

                (address plugin, uint8 functionId) = runtimeValidationFunction.unpack();

                _updatePluginCallBufferFunctionId(callBuffer, functionId);

                _executeRuntimePluginFunction(callBuffer, plugin, RuntimeValidationFunctionReverted.selector);
            }
        }
    }

    /// @dev Executes pre-exec hooks and returns the post-exec hooks to run and their associated args.
    function _doPreExecHooks(SelectorData storage selectorData, bytes memory callBuffer)
        internal
        returns (FunctionReference[][] memory postHooksToRun, bytes[] memory postHookArgs)
    {
        FunctionReference[] memory preExecHooks;

        bool hasPreExecHooks = selectorData.hasPreExecHooks;
        bool hasPostOnlyExecHooks = selectorData.hasPostOnlyExecHooks;

        if (hasPreExecHooks) {
            preExecHooks = CastLib.toFunctionReferenceArray(selectorData.executionHooks.preHooks.getAll());
        }

        // Allocate memory for the post hooks and post hook args.
        // If we have post-only hooks, we allocate an extra FunctionReference[] for them, and one extra element
        // in the args for their empty `bytes` argument.
        uint256 postHooksToRunLength = preExecHooks.length + (hasPostOnlyExecHooks ? 1 : 0);
        postHooksToRun = new FunctionReference[][](postHooksToRunLength);
        postHookArgs = new bytes[](postHooksToRunLength);

        // If there are no pre exec hooks, this will short-circuit in the length check on `preExecHooks`.
        _cacheAssociatedPostHooks(preExecHooks, selectorData.executionHooks, postHooksToRun);

        if (hasPostOnlyExecHooks) {
            // If we have post-only hooks, we allocate an single FunctionReference[] for them, and one element
            // in the args for their empty `bytes` argument. We put this into the last element of the post
            // hooks, which means post-only hooks will run before any other post hooks.
            postHooksToRun[postHooksToRunLength - 1] =
                CastLib.toFunctionReferenceArray(selectorData.executionHooks.postOnlyHooks.getAll());
        }

        // Run all pre-exec hooks and capture their outputs.
        _doPreHooks(preExecHooks, callBuffer, postHooksToRun, postHookArgs);
    }

    /// @dev Execute all pre hooks provided, using the call buffer if provided.
    /// Outputs are captured into the `hookReturnData` array, in increasing index starting at 0.
    /// The `postHooks` array is used to determine whether or not to capture the return data.
    function _doPreHooks(
        FunctionReference[] memory preHooks,
        bytes memory callBuffer,
        FunctionReference[][] memory postHooks, // Only used to check if any post hooks exist.
        bytes[] memory hookReturnData
    ) internal {
        uint256 preExecHooksLength = preHooks.length;

        // If not running anything, short-circuit before allocating more memory for the call buffers.
        if (preExecHooksLength == 0) {
            return;
        }

        if (callBuffer.length == 0) {
            // Allocate the call buffer for preExecHook. This case MUST NOT be reached by `executeFromPlugin`,
            // otherwise the call will execute with the wrong calldata. This case should only be reachable by
            // native functions with no runtime validation (e.g., token receiver functions or functions called via
            // a user operation).
            callBuffer = _allocateRuntimeCallBuffer(msg.data);
        }
        _updatePluginCallBufferSelector(callBuffer, IPlugin.preExecutionHook.selector);

        for (uint256 i = 0; i < preExecHooksLength; ++i) {
            FunctionReference preExecHook = preHooks[i];

            if (preExecHook.isEmptyOrMagicValue()) {
                // The function reference must be the Always Deny magic value in this case,
                // because zero and any other magic value is unassignable here.
                revert AlwaysDenyRule();
            }

            (address plugin, uint8 functionId) = preExecHook.unpack();

            _updatePluginCallBufferFunctionId(callBuffer, functionId);

            _executeRuntimePluginFunction(callBuffer, plugin, PreExecHookReverted.selector);

            // Only collect the return data if there is at least one post-hook to consume it.
            if (postHooks[i].length > 0) {
                hookReturnData[i] = abi.decode(_collectReturnData(), (bytes));
            }
        }
    }

    /// @dev Executes all post hooks in the nested array, using the corresponding args in the nested array.
    /// Executes the elements in reverse order, so the caller should ensure the correct ordering before calling.
    function _doCachedPostHooks(FunctionReference[][] memory postHooks, bytes[] memory postHookArgs) internal {
        // Run post hooks in reverse order of their associated pre hooks.
        uint256 postHookArrsLength = postHooks.length;
        for (uint256 i = postHookArrsLength; i > 0;) {
            uint256 index;
            unchecked {
                // i starts as the length of the array and goes to 1, not zero, to avoid underflowing.
                // To use the index for array access, we need to subtract 1.
                index = i - 1;
            }
            FunctionReference[] memory postHooksToRun = postHooks[index];

            // We don't need to run each associated post-hook in reverse order, because the associativity we want
            // to maintain is reverse order of associated pre-hooks.
            uint256 postHooksToRunLength = postHooksToRun.length;
            for (uint256 j = 0; j < postHooksToRunLength; ++j) {
                (address plugin, uint8 functionId) = postHooksToRun[j].unpack();

                // Execute the post hook with the current post hook args
                // solhint-disable-next-line no-empty-blocks
                try IPlugin(plugin).postExecutionHook(functionId, postHookArgs[index]) {}
                catch (bytes memory revertReason) {
                    revert PostExecHookReverted(plugin, functionId, revertReason);
                }
            }

            // Solidity v0.8.22 allows the optimizer to automatically remove checking on for loop increments, but
            // not decrements. Therefore we need to use unchecked here to avoid the extra costs for checked math.
            unchecked {
                --i;
            }
        }
    }

    /// @inheritdoc UUPSUpgradeable
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override {}

    /// @dev Override to implement custom behavior.
    function _tokensReceived(address, address, address, uint256, bytes calldata, bytes calldata)
        internal
        virtual
    // solhint-disable-next-line no-empty-blocks
    {}

    /// @dev Override to implement custom behavior.
    function _onERC721Received(address, address, uint256, bytes calldata)
        internal
        virtual
        returns (bytes4 selector)
    {
        selector = IERC721Receiver.onERC721Received.selector;
    }

    /// @dev Override to implement custom behavior.
    function _onERC1155Received(address, address, uint256, uint256, bytes calldata)
        internal
        virtual
        returns (bytes4 selector)
    {
        selector = IERC1155Receiver.onERC1155Received.selector;
    }

    /// @dev Override to implement custom behavior.
    function _onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        internal
        virtual
        returns (bytes4 selector)
    {
        selector = IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    /// @dev Loads the associated post hooks for the given pre-exec hooks in the `postHooks` array, starting at 0.
    function _cacheAssociatedPostHooks(
        FunctionReference[] memory preExecHooks,
        HookGroup storage hookGroup,
        FunctionReference[][] memory postHooks
    ) internal view {
        uint256 preExecHooksLength = preExecHooks.length;
        for (uint256 i = 0; i < preExecHooksLength; ++i) {
            FunctionReference preExecHook = preExecHooks[i];

            // If the pre-exec hook has associated post hooks, cache them in the postHooks array.
            if (hookGroup.preHooks.flagsEnabled(CastLib.toSetValue(preExecHook), _PRE_EXEC_HOOK_HAS_POST_FLAG)) {
                postHooks[i] =
                    CastLib.toFunctionReferenceArray(hookGroup.associatedPostHooks[preExecHook].getAll());
            }
            // In no-associated-post-hooks case, we're OK returning the default value, which is an array of length
            // 0.
        }
    }

    /// @dev Revert with an appropriate error if the calldata does not include a function selector.
    function _selectorFromCallData(bytes calldata data) internal pure returns (bytes4) {
        if (data.length < 4) {
            revert UnrecognizedFunction(bytes4(data));
        }
        return bytes4(data);
    }
}

// src/MessagingPlugin.sol
/// This file is part of Modular Account v1.0.0
///
///
///

///
///
/// note: MessagingPlugin works ONLY with Smart Sccounts who installed MultiOwnerPlugin.
/// That's one of the key benefits of using MultiOwnerPlugin as our validation dependency leveraging the MultiOwnerAccountFactory in deployment.
/// For example, multiple owners created with MultiOwnerPlugin can access to our MessagingPlugin operations by design.

contract MessagingPlugin is BasePlugin, IERC1271, IMessagingPlugin {

    // Libraries for linked list storage and casting values
    using AssociatedLinkedListSetLib for AssociatedLinkedListSet;
    using ECDSA for bytes32;
    using Address for address;

    // Plugin metadata
    string internal constant _NAME = "Messaging Plugin";
    string internal constant _VERSION = "0.0.1 | Alpha";
    string internal constant _AUTHOR = "Michele Galante";

    // EIP712 domain separator
    bytes32 private constant _TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
    );

    // Hashed values for EIP712 domain separator
    bytes32 private constant _HASHED_NAME = keccak256(bytes(_NAME));
    bytes32 private constant _HASHED_VERSION = keccak256(bytes(_VERSION));
    bytes32 private immutable _SALT = bytes32(bytes20(address(this)));

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant _1271_MAGIC_VALUE = 0x1626ba7e;
    bytes4 internal constant _1271_MAGIC_VALUE_FAILURE = 0xffffffff;

    // Typehashes for EIP-712
    bytes32 private constant MODULAR_ACCOUNT_TYPEHASH = keccak256("AlchemyModularAccountMessage(bytes message)");
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("Message(address from,address to,string content,uint256 nonce,uint256 timestamp)");

    // Helpers error messages
    bytes30 internal constant ACCOUNT_ENABLED_VALUE = bytes30(uint240(1));
    uint256 private constant MAX_UINT240 = type(uint240).max;

    // Manifest dependency indexes from MultiOwnerPlugin
    uint256 internal constant _MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION = 0;
    uint256 internal constant _MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION = 1;

    // Manifest dependency indexes as public functions so tests can access them
    function MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION() public pure returns (uint256) { return 0; }
    function MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION() public pure returns (uint256) { return 1; }

    // Message structure
    struct Message {
        address from;
        address to;
        string content;
        uint256 nonce;
        uint256 timestamp;
    }
    
    uint256 internal constant MAX_MESSAGE_LENGTH = 300; // Character limit reducing gas costs

    // Storage for messages and enabled accounts
    AssociatedLinkedListSet internal _messages;
    AssociatedLinkedListSet internal _enabledAccounts;

    // Nonces for messages and accounts
    mapping(address => uint256) private _messageNonces;
    mapping(address => uint256) private _accountNonces;

    // Messages stored by their full hash
    mapping(bytes32 => Message) private _messageDetails;

    // Additional mapping for timestamp-based retrieval
    mapping(address => mapping(address => bytes32[])) private _conversationMessages;

    // Plugin implementation 
    function moduleId() external pure returns (string memory) {
        return string(abi.encodePacked(_AUTHOR, ".", _NAME, ".", _VERSION));
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Execution function     ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    function sendMessage(address to, string calldata msgContent) external override {

        // Check if the account is enabled
        if (!_isInitialized(msg.sender)) revert NotAuthorized(msg.sender);
        if (!_isInitialized(to)) revert InvalidRecipient(to);
        if (bytes(msgContent).length > MAX_MESSAGE_LENGTH) revert MessageTooLong();

        // Increment message nonce
        uint256 messageNonce = _messageNonces[msg.sender];
        if (messageNonce >= MAX_UINT240) revert MessageNonceOverflow(msg.sender);
        _messageNonces[msg.sender] = messageNonce + 1;

        // Create new message
        Message memory newMessage = Message({
            from: msg.sender,
            to: to,
            content: msgContent,
            nonce: messageNonce,
            timestamp: block.timestamp
        });

        // Store message details
        bytes32 messageHash = _hashMessage(newMessage);
        if (_messageDetails[messageHash].timestamp != 0) {
            revert MessageHashCollision(messageHash);
        }

        // Store full message details
        _messageDetails[messageHash] = newMessage;

        // Store full hash in conversation history
        _conversationMessages[msg.sender][to].push(messageHash);
        _conversationMessages[to][msg.sender].push(messageHash);

        // Convert messageHash to SetValue for linked list storage
        bytes30 truncatedHash = bytes30(uint240(uint256(messageHash)));
        SetValue messageValue = SetValue.wrap(truncatedHash);
        
        // Store message hash in both participants' lists
        bool senderAdded = _messages.tryAdd(msg.sender, messageValue);
        bool recipientAdded = _messages.tryAdd(to, messageValue);
        
        // Revert if either participant's list storage fails
        if (!senderAdded || !recipientAdded) {
            revert MessageStorageFailure(msg.sender, to);
        }

        emit MessageSent(msg.sender, to, msgContent);
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃  Execution view function    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    function getChat(address with) external view override returns (string[] memory) {

        // Retrieve all message hashes for the conversation
        bytes32[] memory conversationHashes = _conversationMessages[msg.sender][with];
        
        // Create array for chronologically ordered messages
        Message[] memory orderedMessages = new Message[](conversationHashes.length);
        uint256 validCount = 0;

        // Retrieve all valid messages
        for (uint256 i = 0; i < conversationHashes.length; i++) {
            Message memory msg_ = _messageDetails[conversationHashes[i]];
            if (msg_.timestamp != 0 && 
                ((msg_.from == msg.sender && msg_.to == with) || 
                 (msg_.from == with && msg_.to == msg.sender))) {
                orderedMessages[validCount] = msg_;
                validCount++;
            }
        }

        // Sort messages by timestamp using insertion sort
        for (uint256 i = 1; i < validCount; i++) {
            Message memory key = orderedMessages[i];
            int256 j = int256(i) - 1;
            
            while (j >= 0 && orderedMessages[uint256(j)].timestamp > key.timestamp) {
                orderedMessages[uint256(j + 1)] = orderedMessages[uint256(j)];
                j--;
            }
            orderedMessages[uint256(j + 1)] = key;
        }

        // Create final array with message contents
        string[] memory chatMessages = new string[](validCount);
        for (uint256 i = 0; i < validCount; i++) {
            chatMessages[i] = orderedMessages[i].content;
        }

        return chatMessages;
    }

    // ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
    // ┃    Plugin interface functions    ┃
    // ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

    function _onInstall(bytes calldata) internal override isNotInitialized(msg.sender) {

        // Check if the caller is a smart account
        if (!Address.isContract(msg.sender)) revert NotContractCaller(msg.sender);

        // Increment account nonce
        uint256 nonce = _accountNonces[msg.sender];
        
        // Check for nonce overflow
        if (nonce >= MAX_UINT240) revert AccountNonceOverflow(msg.sender);
        _accountNonces[msg.sender] = nonce + 1;
        
        // Add account to enabled smart accounts with messaging plugin installed
        require(_enabledAccounts.tryAdd(msg.sender, SetValue.wrap(ACCOUNT_ENABLED_VALUE)), "Failed to initialize");
    }

    function onUninstall(bytes calldata) external override {

        // Clean up all messages for the account
        SetValue[] memory messageHashes = _messages.getAll(msg.sender);
        for (uint256 i = 0; i < messageHashes.length; i++) {
            _messages.tryRemove(msg.sender, messageHashes[i]);
        }
        
        // Remove account from enabled accounts
        require(_enabledAccounts.tryRemove(msg.sender, SetValue.wrap(ACCOUNT_ENABLED_VALUE)), "Failed to uninstall");
    }

     function _isInitialized(address account) internal view override returns (bool) {

        // Check if the smart account is enabled
        return _enabledAccounts.contains(account, SetValue.wrap(ACCOUNT_ENABLED_VALUE));
    }

    function _hashMessage(Message memory message) internal pure returns (bytes32) {

        // Hash the message data
        return keccak256(
            abi.encode(
                MESSAGE_TYPEHASH,
                message.from,
                message.to,
                keccak256(bytes(message.content)),
                message.nonce,
                message.timestamp
            )
        );
    }

    // ERC-1271 Implementation
    function eip712Domain()
        external
        view
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        // Return EIP712 domain data 
        return (
            hex"1f", // 11111 indicate salt field is also used
            _NAME,
            _VERSION,
            block.chainid,
            msg.sender,
            _SALT,
            new uint256[](0)
        );
    }

    function isValidSignature(bytes32 digest, bytes memory signature) external view override returns (bytes4) {

        // Recover the signer from the signature
        bytes32 messageHash = getMessageHash(msg.sender, abi.encode(digest));
        
        // Validate the signature or return failure
        (address signer, ECDSA.RecoverError error) = ECDSA.tryRecover(messageHash, signature);
        if (error == ECDSA.RecoverError.NoError && _isInitialized(signer)) {
            return _1271_MAGIC_VALUE;
        }
        return _1271_MAGIC_VALUE_FAILURE;
    }

    function userOpValidationFunction(uint8 /*functionId*/, UserOperation calldata /*userOp*/, bytes32 /*userOpHash*/) external pure override returns (uint256) {
        
/*
        // Validate the user operation and return the result or revert if the smart account is not implemented
        if (functionId == uint8(FunctionId.USER_OP_VALIDATION_OWNER)) {
            (address signer, ECDSA.RecoverError error) = 
                userOpHash.toEthSignedMessageHash().tryRecover(userOp.signature);
            
            if (error == ECDSA.RecoverError.NoError && _isInitialized(signer)) {
                return SIG_VALIDATION_PASSED;
            }
            return SIG_VALIDATION_FAILED;
        }
        revert NotImplemented(msg.sig, functionId);   
*/

        /// @dev We're using MultiOwnerPlugin's validation, so we shouldn't implement our own
        /// Instead, we should revert since we're using the dependency
        /// Note: according to ERC-6900, since we're using ManifestAssociatedFunctionType.DEPENDENCY
        /// we should actually let these standard-revert and delegate the runtime execution to MultiOwnerPlugin (without the NotImplemented error) 
        revert();
    }

    function runtimeValidationFunction(uint8 /*functionId*/, address /*sender*/, uint256 /*value*/, bytes calldata /*data*/) external pure override {

/*
        // Validate the runtime function and revert if the sender is not authorized or the function is not implemented for the smart account
        if (functionId == uint8(FunctionId.RUNTIME_VALIDATION_OWNER_OR_SELF)) {
            if (sender != msg.sender && !_isInitialized(sender)) {
                revert NotAuthorized(sender);
            }
            return;
        }
        revert NotImplemented(msg.sig, functionId); 
*/

        /// @dev Similar to runtime validation, we're using MultiOwnerPlugin's validation
        revert();
    }

    function encodeMessageData(address account, bytes memory message) public view returns (bytes memory) {

        // Encode the message data for EIP712 signing
        bytes32 messageHash = keccak256(abi.encode(MODULAR_ACCOUNT_TYPEHASH, keccak256(message)));
        return abi.encodePacked("\x19\x01", _domainSeparator(account), messageHash);
    }

    function getMessageHash(address account, bytes memory message) public view returns (bytes32) {

        // Return the message hash for EIP712 signing
        return keccak256(encodeMessageData(account, message));
    }

    function _domainSeparator(address account) internal view returns (bytes32) {

        // Return the EIP712 domain separator for the plugin
        return keccak256(
            abi.encode(
                _TYPE_HASH,
                _HASHED_NAME,
                _HASHED_VERSION,
                block.chainid,
                account,
                _SALT
            )
        );
    }

    function pluginManifest() external pure override returns (PluginManifest memory) {

        PluginManifest memory manifest;

        // Define dependencies on MultiOwnerPlugin - need two indices
        manifest.dependencyInterfaceIds = new bytes4[](2);
        manifest.dependencyInterfaceIds[_MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION] = 
            type(IMultiOwnerPlugin).interfaceId;
        manifest.dependencyInterfaceIds[_MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION] = 
            type(IMultiOwnerPlugin).interfaceId;

        // Define execution functions
        manifest.executionFunctions = new bytes4[](2);
        manifest.executionFunctions[0] = this.sendMessage.selector;
        manifest.executionFunctions[1] = this.getChat.selector;

        // User Operation Validation
        manifest.userOpValidationFunctions = new ManifestAssociatedFunction[](1);

        // For sendMessage - delegate to owner validation
        manifest.userOpValidationFunctions[0] = ManifestAssociatedFunction({
            executionSelector: this.sendMessage.selector,
            associatedFunction: ManifestFunction({
                functionType: ManifestAssociatedFunctionType.DEPENDENCY,
                functionId: 0, // unused since it's a dependency
                dependencyIndex: _MANIFEST_DEPENDENCY_INDEX_OWNER_USER_OP_VALIDATION
            })
        });

        // Runtime Validation
        manifest.runtimeValidationFunctions = new ManifestAssociatedFunction[](2);

        // For sendMessage - delegate to owner validation
        manifest.runtimeValidationFunctions[0] = ManifestAssociatedFunction({
            executionSelector: this.sendMessage.selector,
            associatedFunction: ManifestFunction({
                functionType: ManifestAssociatedFunctionType.DEPENDENCY,
                functionId: 0, // unused since it's a dependency
                dependencyIndex: _MANIFEST_DEPENDENCY_INDEX_OWNER_RUNTIME_VALIDATION
            })
        });

        // For getChat - always allow as it's a read-only function
        manifest.runtimeValidationFunctions[1] = ManifestAssociatedFunction({
            executionSelector: this.getChat.selector,
            associatedFunction: ManifestFunction({
                functionType: ManifestAssociatedFunctionType.RUNTIME_VALIDATION_ALWAYS_ALLOW,
                functionId: 0,
                dependencyIndex: 0
            })
        });

        // Support for ERC1271 and MessagingPlugin interfaces
        manifest.interfaceIds = new bytes4[](2);
        manifest.interfaceIds[0] = type(IERC1271).interfaceId;
        manifest.interfaceIds[1] = type(IMessagingPlugin).interfaceId;

        manifest.permitAnyExternalAddress = false;     // This plugin doesn't need to call external contracts
        manifest.canSpendNativeToken = false;          // This plugin doesn't need to spend native tokens

        return manifest;
    }

    function pluginMetadata() external pure override returns (PluginMetadata memory) {
        PluginMetadata memory metadata;
        metadata.name = _NAME;
        metadata.version = _VERSION;
        metadata.author = _AUTHOR;

        // Define permissions for the plugin
        metadata.permissionDescriptors = new SelectorPermission[](1);
        metadata.permissionDescriptors[0] = SelectorPermission({
            functionSelector: this.sendMessage.selector,
            permissionDescription: "Send messages to other accounts"
        });

        return metadata;
    }

    // ┏━━━━━━━━━━━━━━━┓
    // ┃    EIP-165    ┃
    // ┗━━━━━━━━━━━━━━━┛

     function supportsInterface(bytes4 interfaceId) public view override returns (bool) {

        // Check if the smart account supports the interface for the plugin
        return 
            interfaceId == type(IMessagingPlugin).interfaceId || 
            interfaceId == type(IERC1271).interfaceId ||
            super.supportsInterface(interfaceId);
    
    }

}

