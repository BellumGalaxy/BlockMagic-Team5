# MyJourneyNFT Smart Contract

## Descrição

O contrato `MyJourneyNFT` é um contrato inteligente que emite NFTs (tokens não fungíveis) representando diferentes etapas educacionais de um aluno. Este contrato utiliza ERC721 para a emissão de NFTs, Chainlink Functions para a execução de funções fora da cadeia e AccessControl para gerenciamento de permissões.

## Funcionalidades Principais

### Emissão de NFTs

1. **issueNFT**: Emite um NFT para um aluno em uma determinada etapa educacional (Fundamental, Ensino Médio ou Universidade).
2. **issueNFTForStage**: Emite um NFT para uma etapa educacional específica se o aluno ainda não tiver um NFT para essa etapa.

### Gerenciamento de Alunos

1. **addStudent**: Adiciona um novo aluno ao contrato.
2. **getStudentByAddress**: Retorna os detalhes de um aluno com base no endereço.

### Gerenciamento de Administradores e Instituições Financeiras

1. **addAdministrator**: Adiciona um novo administrador.
2. **removeAdministrator**: Remove um administrador existente.
3. **addFinancialInstitution**: Adiciona uma nova instituição financeira autorizada a emitir NFTs.
4. **removeFinancialInstitution**: Remove uma instituição financeira.

### Configuração de Metadados de NFTs

1. **setNFTMetadataURI**: Define o URI dos metadados de um NFT específico.

### Funções Chainlink

1. **sendReponse**: Envia uma solicitação ao Chainlink Functions para executar código JavaScript fora da cadeia e obter uma resposta.
2. **fulfillRequest**: Função de callback que trata a resposta de uma solicitação Chainlink.

## Estrutura do Contrato

### Variáveis de Armazenamento

- `s_tokenIdCounter`: Contador de IDs de tokens.
- `s_students`: Mapeamento de endereços de alunos para suas informações.
- `s_studentEducationStage`: Mapeamento de endereços de alunos para suas etapas educacionais.
- `s_stageNFTLinks`: Mapeamento de etapas educacionais para links de NFTs.
- `s_financialInstitutions`: Mapeamento de endereços de instituições financeiras autorizadas.
- `s_administrators`: Mapeamento de endereços de administradores.
- `s_lastRequestId`: ID da última solicitação Chainlink.
- `s_lastResponse`: Última resposta recebida do Chainlink.
- `s_lastError`: Último erro recebido do Chainlink.

### Variáveis Imutáveis

- `i_router_add`: Endereço do roteador Chainlink Functions.

### Constantes

- `MINTER_ROLE`: Papel de minter.
- `DON_ID`: ID do oracle descentralizado.
- `GAS_LIMIT`: Limite de gás para callbacks.

### Eventos

- `NFTIssued`: Emitido quando um NFT é emitido para um aluno.

### Modificadores

- `onlyFinancialInstitution`: Verifica se o chamador é uma instituição financeira autorizada.
- `onlyAdministrator`: Verifica se o chamador é um administrador.

## Como Usar

### Emissão de um NFT

```solidity
function issueNFT(address _studentAddress) external onlyFinancialInstitution
