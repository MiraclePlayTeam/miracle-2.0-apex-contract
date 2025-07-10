// SPDX-License-Identifier: MIT
//    _______ _______ ___ ___ _______ ______  ___     ___ ______  _______     ___     _______ _______  _______
//   |   _   |   _   |   Y   |   _   |   _  \|   |   |   |   _  \|   _   |   |   |   |   _   |   _   \|   _   |
//   |   1___|.  1___|.  |   |.  1___|.  |   |.  |   |.  |.  |   |.  1___|   |.  |   |.  1   |.  1   /|   1___|
//   |____   |.  __)_|.  |   |.  __)_|.  |   |.  |___|.  |.  |   |.  __)_    |.  |___|.  _   |.  _   \|____   |
//   |:  1   |:  1   |:  1   |:  1   |:  |   |:  1   |:  |:  |   |:  1   |   |:  1   |:  |   |:  1    |:  1   |
//   |::.. . |::.. . |\:.. ./|::.. . |::.|   |::.. . |::.|::.|   |::.. . |   |::.. . |::.|:. |::.. .  |::.. . |
//   `-------`-------' `---' `-------`--- ---`-------`---`--- ---`-------'   `-------`--- ---`-------'`-------'
//   Tournament Event Logger v1.0.1
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/extension/PermissionsEnumerable.sol";
import "@thirdweb-dev/contracts/extension/Multicall.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

contract MiracleTournamentEventLogger is PermissionsEnumerable, Multicall, ContractMetadata{
    
    // 토너먼트 결과 기록을 위한 이벤트 정의
    event TournamentResultLogged(
        uint256 indexed tournamentId,
        string ipfsCid,
        uint256 timestamp
    );

    // 컨트랙트 소유자
    address public deployer;
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    constructor(address _admin, string memory _contractURI) {
        deployer = _admin;
        _setupContractURI(_contractURI);

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(FACTORY_ROLE, _admin);

        _setupRole(FACTORY_ROLE, 0x36205404Ca7dFe48db631B7BbADB57286A2E486a);
        _setupRole(FACTORY_ROLE, 0xB839a747777141FD91E53DA00a986f022b5Ebe3e);
        _setupRole(FACTORY_ROLE, 0xd5AB20464D55c85e5996770d14A567AA140e8fDe);
        _setupRole(FACTORY_ROLE, 0x960c8465B6931C0153Dd233D7C53dfa0DaF45CDa);
        _setupRole(FACTORY_ROLE, 0xF0357FA8D7eF4ad6FF099A9635e2b36eC77Fe979);
        _setupRole(FACTORY_ROLE, 0xF8dc2c9e23298FeD0B721624CaCA7a79E092ED89);
        _setupRole(FACTORY_ROLE, 0x0aa8202803e0Ab80DD2f63651F28BF4B892933fe);
        _setupRole(FACTORY_ROLE, 0x4228dDEb08B1FD561b41Ecc7eebD0C95dee19099);
        _setupRole(FACTORY_ROLE, 0xF5fe16F753E570A442a447817B9aEaEc342b3B72);
        _setupRole(FACTORY_ROLE, 0xfa95EFAdC6Df2927cA23aEe93650979bA2FAe138);
        _setupRole(FACTORY_ROLE, 0xf262b4A6B049c46bCee782f36ce755df04780369);
        _setupRole(FACTORY_ROLE, 0x5E81b89CE9A5Fe9bE209a18BD5C6c96e77B4e0D9);
        _setupRole(FACTORY_ROLE, 0xEd28Ca8715ee0EEdf6f07a6B3Fc6C514132Ec77C);
        _setupRole(FACTORY_ROLE, 0x3f47Fb659a86e67BA5C1A983719FbA005aE27E3e);
        _setupRole(FACTORY_ROLE, 0x2009a1D3590966020D7Cb1dac60b45c5667488cB);
        _setupRole(FACTORY_ROLE, 0xa96C941DDb1DcD36E7E03D5FFbcD2A2825D3009D);
        _setupRole(FACTORY_ROLE, 0xdC48C97939DeCb597FCb51cC8c9a55caE5ecd9B9);
        _setupRole(FACTORY_ROLE, 0x0B47702Ee4A7619f9De9C2d0E3228FB990028AFa);
        _setupRole(FACTORY_ROLE, 0x753e8Fc2dfe66D8ca0B9d2902D04B32226eAC4Db);
        _setupRole(FACTORY_ROLE, 0xAb675dcb0Fe48689f6A44e188FaA8584d30e6ce2);
    }

    function _canSetContractURI() internal view virtual override returns (bool){
        return msg.sender == deployer;
    }

    // 토너먼트 결과 로깅 함수
    function logTournamentResult(uint256 _tournamentId, string memory _ipfsCid) 
        external 
        onlyRole(FACTORY_ROLE) 
    {
        require(bytes(_ipfsCid).length > 0, "IPFS CID cannot be empty");
        
        emit TournamentResultLogged(
            _tournamentId,
            _ipfsCid,
            block.timestamp
        );
    }
}
