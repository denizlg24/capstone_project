#import "@preview/typslides:1.3.3": *

#show: typslides.with(
  ratio: "16-9",
  theme: "bluey",
  font: "Fira Sans",
  font-size: 20pt,
  link-style: "color",
  show-progress: true,
)

#front-slide(
  title: "Reunião Intermédia · 14 Abril 2026",
  subtitle: [AI Based Compilation for Custom Hardware],
  authors: "Deniz Günes",
  info: [Projeto Integrador 25/26, L.EIC, FEUP],
)

#table-of-contents()

#slide(title: "O Problema: Mapeamento em CGRA", outlined: true)[
  #cols(columns: (1fr, 0.6fr), gutter: 2em)[
    *CGRA — Coarse-Grained Reconfigurable Array*
    - Grade de PEs interligados e reconfiguráveis
    - Programação via #stress[mapeamento de DFGs]
    - Métrica chave: #stress[Initiation Interval (II)]

    #framed[*Objetivo:* minimizar II — equivale a maximizar throughput do pipeline]
  ][
    *Por que é difícil?*
    - NP-completo em geral
    - Search Space exponencial com o nº de nós do DFG, e arquitetura do CGRA
    - Heurísticas clássicas (SA, ILP) são lentas e às vezes subótimas
  ]
]

#slide(title: "Primeiro passos")[
  Leitura de papers fundamentais:

  + *SAT-MapIt @satmapit* — mapeamento exato via SAT solving
  + *LISA @li2022lisa* — GNN para gerar labels de mapeamento que reduzem o search space de uma implementação de Simulated Annealing
  + *GEML @Kou2022GEMLGE* — GNN para transformar o problema de mapeamento num problema de isomorfismo de grafos, usado depois numa Deep-Q Network (DQN) para mapeament com um  greedy
  + *NaviMap @11310964* - Itera sobre a ideia do GEML, usando branch-and-bound guiado por DQN
]


#slide(title: "Estado atual", outlined: true)[
  1. *Treinar GNN do LISA para gerar labels*
  #framed(title: "Pipeline")[
    *DFG's sintéticos* → `synthetic_dfg_converter.py` -> *SatMap Input format* → `gnn_label_generator.py` → *Mappings válidos* -> `run_training.sh`
  ]

  *4 Labels geradas pela GNN do LISA:*
  + #stress[Schedule Order] — timeslot a que um nó é mapeado
  + #stress[Same-Level Association] — associação de nós no mesmo nível
  + #stress[Spatial Mapping Distance] — distância espacial esperada entre PEs
  + #stress[Temporal Mapping Distance] — distância temporal entre timesteps

  2. *Mapping com search space reduzido pelas labels do LISA*

  - Em primeiro lugar convertemos os ficheiros de input do SatMap para o formato de input da GNN do LISA.
  - Corremos o gerador de features, para anotar o grafo de DFG com as features necessárias para a GNN.
  - Corremos o gerador de labels, que usa a GNN treinada para gerar os 4 labels para cada nó do DFG, (apenas usamos as ultimas 2)
  - Finalmente, usamos os labels para dar prune a literais do SAT-MapIt, reduzindo o search space e acelerando o solver.
]

#slide(title: "Próximos Passos", outlined: true)[
  1. *Avaliar o impacto das labels no tempo de mapeamento* — avaliar o número de literais pruned.
  2. *Explorar como usar as 2 primeiras labels*
  3. *Melhorar a definição da arquitetura do CGRA* — definir um formato para descrever arquiteturas de CGRA, e dar parse dessas na classe CGRA
  4. *Testar em CGRA 8x8* — de momento a redução de cerca de 48.4% de literais é quase puramente geométrica. Como a GNN foi treinada em apenas 1000 labels, o spacial e temporal distance variam pouco, raramente sendo diferente de 1 ou 2. Num CGRA 4x4 há 256 pares ordernados 48% deles não tem manhattan distance <= 2 (dependendo da topologia)
]

#let bib = bibliography("bibliography.bib")
#bibliography-slide(bib)
