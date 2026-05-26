# Delta para a capability `loops`

## ADDED Requirements

### Requirement: Criação de Marcadores

- **MUST** O sistema DEVE permitir criar um marcador em uma posição da faixa, com um rótulo
opcional, atribuindo a ele um identificador único.

#### Scenario: Marcador criado com sucesso

- **GIVEN** uma faixa com duração conhecida em frames
- **WHEN** um marcador é criado em uma posição dentro dos limites da faixa
- **THEN** o marcador recebe um identificador único
- **AND** passa a constar na lista de marcadores

#### Scenario: Marcador fora dos limites da faixa

- **GIVEN** uma faixa com duração conhecida em frames
- **WHEN** um marcador é criado em uma posição maior que a duração da faixa
- **THEN** a criação é rejeitada com o erro `OutOfBounds`

### Requirement: Definição da Região de Loop

- **MUST** O sistema DEVE permitir definir uma região de loop a partir de uma posição de
início e uma de fim, interpretadas como o intervalo semiaberto `[início, fim)`.

#### Scenario: Região válida

- **GIVEN** uma faixa com duração conhecida
- **WHEN** uma região é definida com início estritamente menor que o fim e ambos dentro dos limites
- **THEN** a região passa a ser a região de loop atual

#### Scenario: Região vazia ou invertida

- **GIVEN** uma faixa com duração conhecida
- **WHEN** uma região é definida com início maior ou igual ao fim
- **THEN** a definição é rejeitada com o erro `EmptyRegion`

#### Scenario: Região fora dos limites

- **GIVEN** uma faixa com duração conhecida
- **WHEN** uma região é definida com o fim além da duração da faixa
- **THEN** a definição é rejeitada com o erro `OutOfBounds`

### Requirement: Ativação do Loop

- **MUST** O sistema DEVE permitir ativar e desativar o loop e DEVE expor o estado atual,
incluindo se está ativo e qual é a região, quando houver.

#### Scenario: Alternar o estado do loop

- **GIVEN** uma região de loop definida
- **WHEN** o loop é ativado e em seguida desativado
- **THEN** o estado consultado reflete cada alteração

### Requirement: Reposicionamento da Reprodução em Loop

- **MUST** Com o loop ativo, quando a posição de reprodução avança e atinge ou ultrapassa o
fim da região, o sistema DEVE reposicioná-la para o início da região,
preservando o excedente para manter a continuidade temporal.

#### Scenario: Avanço dentro da região

- **GIVEN** um loop ativo e a posição dentro da região
- **WHEN** a posição avança sem atingir o fim da região
- **THEN** a nova posição é a soma simples, sem reposicionamento

#### Scenario: Avanço que cruza o fim da região

- **GIVEN** um loop ativo e a posição dentro da região
- **WHEN** a posição avança e ultrapassa o fim da região
- **THEN** a nova posição é o início da região somado ao excedente

#### Scenario: Avanço maior que a região

- **GIVEN** um loop ativo
- **WHEN** o número de frames avançados é maior que o tamanho da região
- **THEN** a posição resultante é calculada por módulo do tamanho da região

#### Scenario: Loop inativo

- **GIVEN** um loop inativo
- **WHEN** a posição avança além do fim da região
- **THEN** nenhum reposicionamento ocorre e a posição avança normalmente