// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Ballot {
    
    //Estrutura que representa os residentes do condominio
    struct Resident {
        uint weight; //Caso uma pessoa delegue o seu voto a outro residente
        bool voted; //Indica se a pessoa ja votou ou nao
        address delegate; //Endereco do residente que votara por esse residente
        uint vote; //Indice do candidato votado pelo residente
    }

    //Estrutura que define os candidatos a sindico
    struct ApartmentManagerProposal {
        string name;   // Nome do candidato
        uint voteCount; // Numero de votos acumulados
    }

    address public apartmentmanager; //Endereco do sindico atual que cria o contrato da votacao

    mapping(address => Resident) public residents; //Mapeia um endereco com um morador

    ApartmentManagerProposal[] public proposals; //Array de candidato

    //Construtor
    constructor(string[] memory proposalNames) {
        apartmentmanager = msg.sender; //Sindico eh aquele que envia o contrato
        residents[apartmentmanager].weight = 1;

        //Preenche a array dos candidatos
        for (uint i = 0; i < proposalNames.length; i++) {
            proposals.push(ApartmentManagerProposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }
    
    //Sindico permite que os moradores votem por meio do peso do voto
    function giveRightToVote(address resident) public {
        require(
            msg.sender == apartmentmanager,
            "Apenas o síndico pode permitir que os moradores votem!"
        );//Requer que seja o sindico atual
        require(
            !residents[resident].voted,
            "Morador já votou!"
        );//Requer que o morador nao tenha votado
        require(residents[resident].weight == 0); //Requer que o morador nao esteja permitdo para votar antes
        residents[resident].weight = 1;
    }

    //Funcao que permite que um morador delegue seu voto para outro
    function delegate(address to) public {
        Resident storage sender = residents[msg.sender]; 
        require(!sender.voted, "Morador já votou!");//Requer que o morador nao tenha votado ja
        require(to != msg.sender, "Não é possível delegar a si mesmo!");//Requer que o morador nao delegue a ele mesmo

        //Loop para propagar a delegacao caso o morador escolhido tambem delegue seu voto
        while (residents[to].delegate != address(0)) {
            to = residents[to].delegate;

            //Verifica se nao ha um loop de delegacao
            require(to != msg.sender, "Found loop in delegation.");
        }
        sender.voted = true;//Morador votou
        sender.delegate = to;//Registra a delegacao

        Resident storage delegate_ = residents[to];
        if (delegate_.voted) {
            //Registra mais um voto para o candidato que o morador delegado votou
            proposals[delegate_.vote].voteCount += sender.weight;
        } else {
            //Aumenta o peso do voto do morador delegado
            delegate_.weight += sender.weight;
        }
    }

    //Função que registra o voto
    function vote(uint proposal) public {
        Resident storage sender = residents[msg.sender];
        require(sender.weight != 0, "Morador não autenticado!");//Requer que o morador tenha sido autenticado pelo sindico
        require(!sender.voted, "Morador já votou!");//Requer que o morador nao tenha votado antes
        sender.voted = true;

        proposals[proposal].voteCount += sender.weight;//Adiciona o voto ao candidato
    }

    //Função que retorna o indice do ganhador da votacao
    function winningProposal() public view
            returns (uint winningProposal_)
    {
        uint winningVoteCount = 0;
        //Loop para selecionar o candidato com mais votos
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    //Função que retorna o nome do ganhador da votacao
    function winnerName() public view
            returns (string memory winnerName_)
    {
        //Retorna o nome baseando-se na funcao anterior
        winnerName_ = proposals[winningProposal()].name;
    }
}
