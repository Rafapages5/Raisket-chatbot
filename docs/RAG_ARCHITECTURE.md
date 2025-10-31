# Arquitectura RAG para Raisket
## Sistema de Consulta de Regulaciones Financieras Mexicanas

---

## 1. ARQUITECTURA GENERAL

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CAPA DE USUARIO                              │
│  [Cliente Web/API] ──> [FastAPI Backend] ──> [Sistema RAG]          │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
         ┌──────────▼─────────┐         ┌──────────▼─────────┐
         │  INGESTA PIPELINE  │         │  QUERY PIPELINE     │
         │   (Offline/Batch)  │         │   (Online/Real-time)│
         └──────────┬─────────┘         └──────────┬─────────┘
                    │                               │
    ┌───────────────┴───────────┐     ┌────────────┴────────────┐
    │                           │     │                         │
┌───▼────┐  ┌────────┐  ┌──────▼─┐  ┌▼──────┐  ┌──────────┐  ┌▼────────┐
│ Parser │->│Chunker │->│Embedder│  │Embedder│->│ Pinecone │->│ Claude  │
│  PDF   │  │        │  │        │  │        │  │ Retrieval│  │  3.5    │
└────────┘  └────────┘  └────┬───┘  └────────┘  └─────┬────┘  └────┬────┘
                             │                         │            │
                    ┌────────▼─────────┐              │            │
                    │   Pinecone DB    │<─────────────┘            │
                    │  (Vector Store)  │                           │
                    │                  │                           │
                    │ • Namespace: SAT │                           │
                    │ • Namespace: CNBV│                           │
                    │ • Namespace: BMX │                           │
                    └──────────────────┘                           │
                                                                   │
    ┌──────────────────────────────────────────────────────────────┘
    │
┌───▼────────────────┐
│  RESPONSE FORMAT   │
│                    │
│ • Answer           │
│ • Citations        │
│ • Source metadata  │
│ • Confidence score │
└────────────────────┘
```

---

## 2. PIPELINE DE INGESTA DE DOCUMENTOS

### 2.1 Arquitectura del Pipeline

```python
"""
INGESTA PIPELINE FLOW:

PDF Files → Extractor → Metadata Enricher → Chunker → Embedder → Vector DB
              ↓             ↓                  ↓         ↓           ↓
         Text+Layout   Tags+Source        Chunks    Vectors     Pinecone
"""
```

### 2.2 Componentes Detallados

#### A. Document Parser (Extracción)
```
Herramientas recomendadas:
├─ PyMuPDF (fitz) - Principal (rápido, preciso)
├─ pdfplumber - Backup para tablas complejas
└─ Unstructured.io - Para layouts complejos

Salida esperada:
{
  "text": "Contenido extraído...",
  "metadata": {
    "filename": "RMF2024.pdf",
    "source": "SAT",
    "document_date": "2024-01-01",
    "pages": 150,
    "version": "1.0"
  },
  "structure": {
    "sections": [...],
    "tables": [...],
    "headers": [...]
  }
}
```

#### B. Metadata Enrichment
```
Extracción automática:
├─ Organismo (SAT/CNBV/Banxico) - Regex pattern matching
├─ Tipo de documento (Circular/Resolución/Lineamiento)
├─ Fecha de publicación - Extracción de metadatos PDF
├─ Número de artículo/sección - Parsing estructural
├─ Vigencia - NLP pattern recognition
└─ Tags semánticos - Clasificación con embeddings
```

#### C. Pre-procesamiento
```python
Pasos:
1. Limpieza de texto
   - Remover headers/footers repetitivos
   - Normalizar espacios y saltos de línea
   - Preservar formato de artículos/incisos

2. Detección de estructura
   - Identificar jerarquía (Título > Capítulo > Artículo)
   - Marcar referencias cruzadas
   - Detectar tablas y fórmulas

3. Enriquecimiento contextual
   - Agregar contexto de sección al chunk
   - Mantener referencia a documento padre
```

---

## 3. ESTRATEGIA DE CHUNKING

### 3.1 Enfoque Híbrido (Recomendado)

```
ESTRATEGIA MULTI-NIVEL:

Nivel 1: Semantic Chunking (Principal)
├─ Tamaño: 400-600 tokens (~1600-2400 chars)
├─ Overlap: 100 tokens (~400 chars)
├─ Método: Sentence-based con respeto a estructura legal
└─ Ventaja: Mantiene contexto semántico completo

Nivel 2: Article-Level Chunking (Complementario)
├─ Tamaño: Variable (artículo completo)
├─ Sin overlap
├─ Método: Basado en estructura del documento
└─ Ventaja: Preserva integridad de artículos

Nivel 3: Parent-Child Chunks (Para precisión)
├─ Child: 200-300 tokens (para retrieval preciso)
├─ Parent: 600-800 tokens (para contexto)
└─ En query: Retrieve child, devolver parent
```

### 3.2 Configuración Recomendada

```python
CHUNK_CONFIG = {
    "method": "hybrid",
    "semantic_chunk": {
        "size": 500,  # tokens
        "overlap": 100,  # tokens
        "min_size": 200,
        "max_size": 700,
        "respect_boundaries": ["article", "section", "paragraph"]
    },
    "article_chunk": {
        "enabled": True,
        "max_size": 2000,  # Para artículos largos, subdividir
        "preserve_complete": True
    },
    "metadata_per_chunk": {
        "document_name": True,
        "page_number": True,
        "section_hierarchy": True,  # "Título II > Capítulo 3 > Artículo 42"
        "article_number": True,
        "chunk_type": True,  # "semantic" o "article"
        "parent_chunk_id": True,  # Para parent-child
        "cross_references": True  # ["Art. 15", "Art. 23"]
    }
}
```

### 3.3 Justificación de Tamaños

```
Por qué 500 tokens?
├─ text-embedding-3-large: límite 8192 tokens
├─ Contexto legal: típicamente 2-3 párrafos
├─ Retrieval: balance entre precisión y contexto
└─ Costo: eficiente para embeddings ($0.13 per 1M tokens)

Por qué 100 tokens overlap?
├─ Previene pérdida de contexto en bordes
├─ Captura referencias cruzadas
├─ ~2-3 oraciones de contexto compartido
└─ Incremento de storage: ~20% (aceptable)
```

---

## 4. PIPELINE DE RETRIEVAL Y GENERACIÓN

### 4.1 Query Flow Completo

```
User Query
    ↓
[1] Query Enhancement (0.2s)
    ├─ Expansión de términos técnicos
    ├─ Detección de tipo de consulta
    └─ Extracción de entidades (SAT, CNBV, etc.)
    ↓
[2] Embedding Generation (0.1s)
    └─ text-embedding-3-large
    ↓
[3] Vector Retrieval (0.3s)
    ├─ Pinecone similarity search
    ├─ Top-k: 20 resultados iniciales
    └─ Filtros: namespace, metadata
    ↓
[4] Reranking (0.2s)
    ├─ BM25 sparse retrieval (hybrid)
    ├─ Cross-encoder scoring (opcional)
    └─ MMR (Maximal Marginal Relevance)
    ↓
[5] Context Assembly (0.1s)
    ├─ Top-5 chunks finales
    ├─ Expansión a parent chunks
    └─ Ordenamiento por relevancia
    ↓
[6] Generation (0.8s)
    ├─ Claude 3.5 Sonnet
    ├─ Structured prompt
    └─ Streaming response
    ↓
[7] Citation Injection (0.1s)
    └─ Formateo con referencias
    ↓
Response to User (Total: ~1.8s)
```

### 4.2 Optimizaciones de Latencia

```python
OPTIMIZATIONS = {
    "caching": {
        "query_embeddings": "Redis - 1 hora TTL",
        "common_queries": "Redis - Respuestas completas, 24h TTL",
        "document_metadata": "In-memory - Toda la sesión"
    },
    "parallel_processing": {
        "embedding + BM25": "Async simultáneo",
        "multiple_namespace_search": "Parallel Pinecone queries"
    },
    "early_stopping": {
        "high_confidence_threshold": 0.85,
        "skip_reranking_if": "score > 0.9"
    },
    "model_selection": {
        "simple_queries": "Claude 3 Haiku (más rápido)",
        "complex_queries": "Claude 3.5 Sonnet"
    }
}
```

---

## 5. SISTEMA DE CITACIONES

### 5.1 Arquitectura de Citations

```
Citation System Components:

1. Chunk-Level Metadata (Durante ingesta)
   {
     "chunk_id": "sat_rmf2024_art42_chunk3",
     "document": "Resolución Miscelánea Fiscal 2024",
     "source": "SAT",
     "article": "Artículo 42",
     "section": "Fracción III",
     "page": 127,
     "paragraph_start": "Las personas físicas...",
     "url": "https://www.sat.gob.mx/...",
     "legal_reference": "RMF 2024 Art. 42 Fracc. III"
   }

2. Retrieval-Time Citation Extraction
   - Mapeo de chunks → documentos fuente
   - Identificación de texto exacto usado
   - Scoring de relevancia por cita

3. Response-Time Citation Formatting
   - Inline citations: [1], [2]
   - Reference list al final
   - Links clickeables
```

### 5.2 Formato de Respuesta con Citaciones

```json
{
  "answer": "Según la regulación, las personas físicas deben presentar su declaración anual antes del 30 de abril [1]. Los ingresos por arrendamiento se consideran ingresos acumulables [2].",
  "citations": [
    {
      "id": 1,
      "document": "Resolución Miscelánea Fiscal 2024",
      "source": "SAT",
      "reference": "Artículo 42, Fracción III",
      "page": 127,
      "excerpt": "Las personas físicas deberán presentar su declaración anual a más tardar el día 30 del mes de abril del año siguiente...",
      "url": "https://www.sat.gob.mx/normatividad/rmf2024#art42",
      "confidence": 0.94
    },
    {
      "id": 2,
      "document": "Ley del Impuesto Sobre la Renta",
      "source": "SAT",
      "reference": "Artículo 114",
      "page": 89,
      "excerpt": "Se consideran ingresos acumulables los provenientes del arrendamiento de inmuebles...",
      "url": "https://www.sat.gob.mx/leyes/lisr#art114",
      "confidence": 0.89
    }
  ],
  "metadata": {
    "query_type": "tax_obligation",
    "entities_detected": ["persona_fisica", "declaracion_anual", "arrendamiento"],
    "confidence_overall": 0.92,
    "sources_count": 2,
    "response_time_ms": 1650
  }
}
```

### 5.3 Técnicas para Citaciones Precisas

```python
CITATION_STRATEGIES = {
    "1. Exact Match Highlighting": {
        "descripcion": "Identificar texto exacto del chunk en respuesta",
        "método": "Fuzzy string matching + token overlap",
        "precision": "Alta (>90%)"
    },
    "2. Semantic Attribution": {
        "descripcion": "Mapear claims semánticos a chunks",
        "método": "Sentence embeddings similarity",
        "precision": "Media (70-85%)"
    },
    "3. Chain-of-Thought Citations": {
        "descripcion": "Pedir a Claude que incluya citas en reasoning",
        "método": "Prompt engineering + structured output",
        "precision": "Alta (85-95%)",
        "recomendado": "SÍ - Mejor para legal"
    },
    "4. Post-Processing Verification": {
        "descripcion": "Verificar que cada claim tenga respaldo",
        "método": "LLM judge + entailment check",
        "precision": "Muy alta (>95%)",
        "costo": "Alto (+1 LLM call)"
    }
}
```

---

## 6. OPTIMIZACIONES DE COSTOS

### 6.1 Análisis de Costos (1,000 queries/mes)

```
ESCENARIO BASE (Sin optimizaciones):

Embeddings (Ingesta - One-time):
├─ 50 PDFs × 150 páginas avg = 7,500 páginas
├─ ~500 tokens/página = 3.75M tokens
├─ Con chunking overlap (~20%) = 4.5M tokens
├─ text-embedding-3-large: $0.13/1M tokens
└─ Costo: $0.58 (one-time)

Embeddings (Queries - Monthly):
├─ 1,000 queries × ~50 tokens/query = 50K tokens
├─ text-embedding-3-large: $0.13/1M tokens
└─ Costo: $0.0065/mes

Claude API (Generation - Monthly):
├─ 1,000 queries × 4,000 tokens input (context) = 4M tokens input
├─ 1,000 queries × 500 tokens output = 500K tokens output
├─ Input: $3.00/1M tokens = $12.00
├─ Output: $15.00/1M tokens = $7.50
└─ Costo: $19.50/mes

Pinecone (Vector DB):
├─ Free tier: 1 index, 100K vectors, 10GB storage
├─ Estimado: 50K vectors (chunks) para 50 PDFs
└─ Costo: $0/mes (dentro de free tier)

TOTAL MENSUAL: ~$20/mes
TOTAL CON INGESTA INICIAL: ~$20.58 first month, $20/mes después
```

### 6.2 Estrategias de Reducción de Costos

```python
COST_OPTIMIZATION_STRATEGIES = {
    "1. Query Caching (40-60% reducción)": {
        "implementación": "Redis con TTL inteligente",
        "ahorro_estimado": "$8-12/mes",
        "detalles": {
            "cache_query_embeddings": "1 hora TTL",
            "cache_full_responses": "Queries comunes, 24h TTL",
            "hit_rate_esperado": "40-50% después de 1 semana"
        }
    },

    "2. Modelo Híbrido (30% reducción)": {
        "implementación": "Router inteligente",
        "ahorro_estimado": "$6/mes",
        "detalles": {
            "claude_haiku": "Queries simples/lookup (3x más barato)",
            "claude_sonnet": "Queries complejas/análisis",
            "clasificador": "Embedding similarity + keywords",
            "split_esperado": "60% Haiku / 40% Sonnet"
        }
    },

    "3. Context Window Optimization (20% reducción)": {
        "implementación": "Retrieval inteligente",
        "ahorro_estimado": "$4/mes",
        "detalles": {
            "adaptive_k": "2-5 chunks según complejidad (no siempre 5)",
            "compression": "Eliminar texto redundante de chunks",
            "parent_expansion": "Solo cuando necesario",
            "avg_tokens_reducción": "4000 → 3200 tokens input"
        }
    },

    "4. Batch Processing (Ingesta)": {
        "implementación": "Procesamiento nocturno",
        "ahorro_estimado": "Tiempo de desarrollo",
        "detalles": {
            "bulk_embedding": "Agrupar requests",
            "error_handling": "Retry logic robusto",
            "incremental_updates": "Solo procesar docs nuevos"
        }
    },

    "5. Prompt Optimization (15% reducción)": {
        "implementación": "Prompts más concisos",
        "ahorro_estimado": "$3/mes",
        "detalles": {
            "system_prompt": "Optimizar longitud",
            "few_shot_examples": "Solo cuando necesario",
            "structured_output": "JSON schema estricto",
            "avg_tokens_reducción": "500 → 425 tokens output"
        }
    }
}

AHORRO TOTAL POTENCIAL: $21-25/mes
COSTO OPTIMIZADO: $5-8/mes (75% reducción)
```

### 6.3 Configuración Recomendada para $100/mes Budget

```
Con $100/mes puedes soportar:
├─ ~5,000 queries/mes (optimizado)
├─ ~2,000 queries/mes (sin optimizar)
├─ 150+ PDFs en vector DB
└─ Actualizaciones mensuales de documentos

Recomendación:
├─ Implementar caching (obligatorio)
├─ Usar modelo híbrido (recomendado)
├─ Context optimization (recomendado)
└─ Prompt optimization (nice to have)
```

---

## 7. EJEMPLOS DE CÓDIGO CONCEPTUAL

### 7.1 Ingesta Pipeline

```python
# ============================================================================
# DOCUMENT INGESTION PIPELINE
# ============================================================================

from typing import List, Dict
import fitz  # PyMuPDF
from langchain.text_splitter import RecursiveCharacterTextSplitter
import openai
from pinecone import Pinecone

class DocumentProcessor:
    """Pipeline de ingesta de documentos regulatorios"""

    def __init__(self, pinecone_api_key: str, openai_api_key: str):
        self.pc = Pinecone(api_key=pinecone_api_key)
        self.index = self.pc.Index("raisket-regulations")
        openai.api_key = openai_api_key

        # Configuración de chunking
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=2000,  # ~500 tokens
            chunk_overlap=400,  # ~100 tokens
            length_function=len,
            separators=["\n\n", "\n", ". ", " ", ""]
        )

    def extract_pdf(self, pdf_path: str) -> Dict:
        """Extrae texto y metadata de PDF"""
        doc = fitz.open(pdf_path)

        # Extraer metadata
        metadata = {
            "filename": pdf_path.split("/")[-1],
            "source": self._detect_source(pdf_path),  # SAT, CNBV, Banxico
            "pages": len(doc),
            "creation_date": doc.metadata.get("creationDate", ""),
        }

        # Extraer texto con estructura
        full_text = ""
        page_map = {}

        for page_num, page in enumerate(doc, 1):
            text = page.get_text()
            full_text += text
            page_map[len(full_text)] = page_num  # Mapeo posición → página

        return {
            "text": full_text,
            "metadata": metadata,
            "page_map": page_map
        }

    def enrich_metadata(self, text: str, base_metadata: Dict) -> Dict:
        """Enriquece metadata con NLP"""
        enriched = base_metadata.copy()

        # Detectar tipo de documento
        if "resolución miscelánea" in text.lower():
            enriched["doc_type"] = "resolucion_miscelanea"
        elif "circular" in text.lower():
            enriched["doc_type"] = "circular"
        elif "lineamiento" in text.lower():
            enriched["doc_type"] = "lineamiento"

        # Extraer año (regex)
        import re
        year_match = re.search(r"20\d{2}", text[:1000])
        if year_match:
            enriched["year"] = year_match.group()

        # Extraer artículos mencionados
        articles = re.findall(r"artículo\s+(\d+)", text.lower())
        enriched["articles_count"] = len(set(articles))

        return enriched

    def chunk_document(self, text: str, metadata: Dict, page_map: Dict) -> List[Dict]:
        """Divide documento en chunks con metadata"""
        chunks = self.text_splitter.split_text(text)

        chunk_objects = []
        for i, chunk_text in enumerate(chunks):
            # Encontrar página del chunk
            chunk_start = text.find(chunk_text)
            page_num = max([p for pos, p in page_map.items() if pos <= chunk_start], default=1)

            # Extraer contexto estructural
            section = self._extract_section(chunk_text)
            article = self._extract_article(chunk_text)

            chunk_obj = {
                "id": f"{metadata['filename']}_chunk_{i}",
                "text": chunk_text,
                "metadata": {
                    **metadata,
                    "chunk_index": i,
                    "page": page_num,
                    "section": section,
                    "article": article,
                    "char_count": len(chunk_text),
                }
            }
            chunk_objects.append(chunk_obj)

        return chunk_objects

    def generate_embeddings(self, chunks: List[Dict]) -> List[Dict]:
        """Genera embeddings para chunks"""
        texts = [c["text"] for c in chunks]

        # Batch embedding (más eficiente)
        response = openai.embeddings.create(
            model="text-embedding-3-large",
            input=texts
        )

        # Agregar embeddings a chunks
        for chunk, embedding_obj in zip(chunks, response.data):
            chunk["embedding"] = embedding_obj.embedding

        return chunks

    def upsert_to_pinecone(self, chunks: List[Dict], namespace: str):
        """Sube chunks a Pinecone"""
        vectors = [
            {
                "id": chunk["id"],
                "values": chunk["embedding"],
                "metadata": {
                    "text": chunk["text"],
                    **chunk["metadata"]
                }
            }
            for chunk in chunks
        ]

        # Upsert en batches de 100
        batch_size = 100
        for i in range(0, len(vectors), batch_size):
            batch = vectors[i:i+batch_size]
            self.index.upsert(vectors=batch, namespace=namespace)

    def process_document(self, pdf_path: str) -> Dict:
        """Pipeline completo de ingesta"""
        print(f"[1/6] Extrayendo PDF: {pdf_path}")
        extracted = self.extract_pdf(pdf_path)

        print(f"[2/6] Enriqueciendo metadata")
        enriched_metadata = self.enrich_metadata(
            extracted["text"],
            extracted["metadata"]
        )

        print(f"[3/6] Chunking documento")
        chunks = self.chunk_document(
            extracted["text"],
            enriched_metadata,
            extracted["page_map"]
        )

        print(f"[4/6] Generando embeddings ({len(chunks)} chunks)")
        chunks_with_embeddings = self.generate_embeddings(chunks)

        print(f"[5/6] Subiendo a Pinecone")
        namespace = enriched_metadata["source"].lower()  # sat, cnbv, banxico
        self.upsert_to_pinecone(chunks_with_embeddings, namespace)

        print(f"[6/6] Completado: {len(chunks)} chunks procesados")
        return {
            "status": "success",
            "chunks_count": len(chunks),
            "namespace": namespace,
            "metadata": enriched_metadata
        }

    # Helper methods
    def _detect_source(self, filename: str) -> str:
        filename_lower = filename.lower()
        if "sat" in filename_lower:
            return "SAT"
        elif "cnbv" in filename_lower or "comision" in filename_lower:
            return "CNBV"
        elif "banxico" in filename_lower or "banco de mexico" in filename_lower:
            return "Banxico"
        return "Unknown"

    def _extract_section(self, text: str) -> str:
        """Extrae título de sección del texto"""
        import re
        # Buscar patrones como "Título II", "Capítulo III"
        match = re.search(r"(título|capítulo)\s+[IVX]+", text.lower())
        return match.group() if match else ""

    def _extract_article(self, text: str) -> str:
        """Extrae número de artículo del texto"""
        import re
        match = re.search(r"artículo\s+(\d+)", text.lower())
        return f"Artículo {match.group(1)}" if match else ""


# ============================================================================
# USO DEL PIPELINE
# ============================================================================

processor = DocumentProcessor(
    pinecone_api_key="your-key",
    openai_api_key="your-key"
)

# Procesar un documento
result = processor.process_document("data/regulations/SAT_RMF_2024.pdf")

# Procesar múltiples documentos
import os
pdf_folder = "data/regulations/"
for filename in os.listdir(pdf_folder):
    if filename.endswith(".pdf"):
        pdf_path = os.path.join(pdf_folder, filename)
        processor.process_document(pdf_path)
```

### 7.2 Query Pipeline con Retrieval y Generation

```python
# ============================================================================
# QUERY PIPELINE - RAG System
# ============================================================================

from typing import List, Dict, Optional
import openai
from pinecone import Pinecone
import anthropic
from rank_bm25 import BM25Okapi
import numpy as np

class RAGQueryEngine:
    """Motor de consultas RAG para regulaciones"""

    def __init__(self, pinecone_api_key: str, openai_api_key: str, anthropic_api_key: str):
        self.pc = Pinecone(api_key=pinecone_api_key)
        self.index = self.pc.Index("raisket-regulations")
        openai.api_key = openai_api_key
        self.claude = anthropic.Anthropic(api_key=anthropic_api_key)

        # Cache (simple in-memory, usar Redis en producción)
        self.query_cache = {}

    async def query(self,
                   question: str,
                   namespace: Optional[str] = None,
                   top_k: int = 5) -> Dict:
        """Pipeline completo de query"""

        # [1] Query Enhancement
        enhanced_query = self._enhance_query(question)

        # [2] Check Cache
        cache_key = f"{enhanced_query}_{namespace}_{top_k}"
        if cache_key in self.query_cache:
            print("[Cache HIT]")
            return self.query_cache[cache_key]

        # [3] Generate Embedding
        query_embedding = self._embed_query(enhanced_query)

        # [4] Vector Retrieval
        retrieved_chunks = self._retrieve_chunks(
            query_embedding,
            namespace,
            top_k=top_k * 4  # Retrieve 4x para reranking
        )

        # [5] Reranking
        reranked_chunks = self._rerank_chunks(enhanced_query, retrieved_chunks, top_k)

        # [6] Context Assembly
        context = self._assemble_context(reranked_chunks)

        # [7] Generation with Claude
        response = self._generate_response(question, context)

        # [8] Citation Injection
        response_with_citations = self._add_citations(response, reranked_chunks)

        # [9] Cache Result
        self.query_cache[cache_key] = response_with_citations

        return response_with_citations

    def _enhance_query(self, question: str) -> str:
        """Mejora la query con expansión de términos"""
        # Expansión simple de términos técnicos
        expansions = {
            "ISR": "Impuesto Sobre la Renta",
            "IVA": "Impuesto al Valor Agregado",
            "RFC": "Registro Federal de Contribuyentes",
            "CFDI": "Comprobante Fiscal Digital por Internet",
        }

        enhanced = question
        for abbr, full in expansions.items():
            if abbr in question:
                enhanced += f" {full}"

        return enhanced

    def _embed_query(self, query: str) -> List[float]:
        """Genera embedding para query"""
        response = openai.embeddings.create(
            model="text-embedding-3-large",
            input=query
        )
        return response.data[0].embedding

    def _retrieve_chunks(self,
                        embedding: List[float],
                        namespace: Optional[str],
                        top_k: int) -> List[Dict]:
        """Retrieval desde Pinecone"""
        query_params = {
            "vector": embedding,
            "top_k": top_k,
            "include_metadata": True
        }

        if namespace:
            query_params["namespace"] = namespace

        results = self.index.query(**query_params)

        # Convertir a formato más amigable
        chunks = []
        for match in results.matches:
            chunks.append({
                "id": match.id,
                "score": match.score,
                "text": match.metadata.get("text", ""),
                "metadata": match.metadata
            })

        return chunks

    def _rerank_chunks(self, query: str, chunks: List[Dict], top_k: int) -> List[Dict]:
        """Reranking con BM25 + MMR"""

        # BM25 Reranking
        tokenized_corpus = [chunk["text"].split() for chunk in chunks]
        bm25 = BM25Okapi(tokenized_corpus)
        bm25_scores = bm25.get_scores(query.split())

        # Combinar scores (70% vector, 30% BM25)
        for chunk, bm25_score in zip(chunks, bm25_scores):
            chunk["combined_score"] = (
                0.7 * chunk["score"] +
                0.3 * (bm25_score / (max(bm25_scores) + 1e-10))
            )

        # Ordenar por score combinado
        chunks_sorted = sorted(chunks, key=lambda x: x["combined_score"], reverse=True)

        # MMR (Maximal Marginal Relevance) para diversidad
        selected = []
        remaining = chunks_sorted.copy()

        while len(selected) < top_k and remaining:
            if not selected:
                selected.append(remaining.pop(0))
            else:
                # Calcular MMR score
                mmr_scores = []
                for chunk in remaining:
                    relevance = chunk["combined_score"]

                    # Diversidad: penalizar similitud con ya seleccionados
                    max_sim = max([
                        self._text_similarity(chunk["text"], s["text"])
                        for s in selected
                    ])

                    mmr_score = 0.7 * relevance - 0.3 * max_sim
                    mmr_scores.append((chunk, mmr_score))

                # Seleccionar el de mayor MMR
                best_chunk = max(mmr_scores, key=lambda x: x[1])[0]
                selected.append(best_chunk)
                remaining.remove(best_chunk)

        return selected

    def _text_similarity(self, text1: str, text2: str) -> float:
        """Similitud simple basada en palabras compartidas"""
        words1 = set(text1.lower().split())
        words2 = set(text2.lower().split())
        intersection = words1.intersection(words2)
        union = words1.union(words2)
        return len(intersection) / len(union) if union else 0

    def _assemble_context(self, chunks: List[Dict]) -> str:
        """Ensambla contexto para el prompt"""
        context_parts = []

        for i, chunk in enumerate(chunks, 1):
            metadata = chunk["metadata"]

            header = f"[Documento {i}]"
            source = f"Fuente: {metadata.get('source', 'N/A')}"
            doc = f"Documento: {metadata.get('filename', 'N/A')}"
            ref = f"Referencia: {metadata.get('article', 'N/A')}, Página {metadata.get('page', 'N/A')}"
            text = f"Contenido:\n{chunk['text']}"

            context_parts.append(f"{header}\n{source}\n{doc}\n{ref}\n{text}\n")

        return "\n---\n".join(context_parts)

    def _generate_response(self, question: str, context: str) -> Dict:
        """Genera respuesta con Claude"""

        system_prompt = """Eres un asistente experto en regulaciones financieras mexicanas.

Tu trabajo es responder preguntas basándote ÚNICAMENTE en el contexto proporcionado.

INSTRUCCIONES CRÍTICAS:
1. Solo usa información del contexto proporcionado
2. Si no tienes suficiente información, di "No tengo suficiente información en los documentos para responder esto"
3. SIEMPRE incluye citas en formato [N] donde N es el número del documento
4. Sé preciso con referencias legales (artículos, fracciones, etc.)
5. Si mencionas un dato específico, DEBE estar respaldado por una cita
6. Usa lenguaje claro pero profesional

FORMATO DE RESPUESTA:
- Respuesta concisa y directa
- Citas inline como [1], [2]
- Si hay múltiples interpretaciones, mencionarlas"""

        user_prompt = f"""Contexto de documentos regulatorios:

{context}

---

Pregunta del usuario: {question}

Responde la pregunta usando SOLO la información del contexto. Incluye citas [N] para cada afirmación."""

        # Llamada a Claude
        message = self.claude.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            system=system_prompt,
            messages=[
                {"role": "user", "content": user_prompt}
            ]
        )

        answer_text = message.content[0].text

        return {
            "answer": answer_text,
            "model": "claude-3-5-sonnet",
            "tokens_input": message.usage.input_tokens,
            "tokens_output": message.usage.output_tokens,
        }

    def _add_citations(self, response: Dict, chunks: List[Dict]) -> Dict:
        """Agrega información detallada de citaciones"""

        citations = []
        for i, chunk in enumerate(chunks, 1):
            metadata = chunk["metadata"]

            citation = {
                "id": i,
                "document": metadata.get("filename", "Documento desconocido"),
                "source": metadata.get("source", "N/A"),
                "reference": metadata.get("article", "N/A"),
                "page": metadata.get("page", "N/A"),
                "excerpt": chunk["text"][:200] + "...",  # Primeros 200 chars
                "confidence": round(chunk.get("combined_score", chunk["score"]), 2),
                "url": self._generate_document_url(metadata)
            }
            citations.append(citation)

        response["citations"] = citations
        response["metadata"] = {
            "sources_count": len(citations),
            "confidence_overall": round(np.mean([c["confidence"] for c in citations]), 2)
        }

        return response

    def _generate_document_url(self, metadata: Dict) -> str:
        """Genera URL al documento original (si está disponible)"""
        source = metadata.get("source", "")
        filename = metadata.get("filename", "")

        # URLs de ejemplo (ajustar según fuentes reales)
        if source == "SAT":
            return f"https://www.sat.gob.mx/normatividad/{filename}"
        elif source == "CNBV":
            return f"https://www.cnbv.gob.mx/normatividad/{filename}"
        elif source == "Banxico":
            return f"https://www.banxico.org.mx/normatividad/{filename}"

        return "#"


# ============================================================================
# USO DEL QUERY ENGINE
# ============================================================================

rag_engine = RAGQueryEngine(
    pinecone_api_key="your-key",
    openai_api_key="your-key",
    anthropic_api_key="your-key"
)

# Query simple
result = await rag_engine.query(
    question="¿Cuándo deben presentar declaración anual las personas físicas?",
    namespace="sat"  # Opcional: buscar solo en documentos del SAT
)

print(result["answer"])
print("\nCitaciones:")
for citation in result["citations"]:
    print(f"[{citation['id']}] {citation['document']} - {citation['reference']}")
```

### 7.3 FastAPI Integration

```python
# ============================================================================
# FASTAPI ENDPOINTS
# ============================================================================

from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel
from typing import Optional, List
import asyncio

app = FastAPI(title="Raisket RAG API")

# Inicializar RAG engine (singleton)
rag_engine = RAGQueryEngine(
    pinecone_api_key=os.getenv("PINECONE_API_KEY"),
    openai_api_key=os.getenv("OPENAI_API_KEY"),
    anthropic_api_key=os.getenv("ANTHROPIC_API_KEY")
)

class QueryRequest(BaseModel):
    question: str
    namespace: Optional[str] = None
    top_k: int = 5

class Citation(BaseModel):
    id: int
    document: str
    source: str
    reference: str
    page: int
    excerpt: str
    confidence: float
    url: str

class QueryResponse(BaseModel):
    answer: str
    citations: List[Citation]
    metadata: dict

@app.post("/api/query", response_model=QueryResponse)
async def query_regulations(request: QueryRequest):
    """Endpoint principal para consultas RAG"""
    try:
        result = await rag_engine.query(
            question=request.question,
            namespace=request.namespace,
            top_k=request.top_k
        )
        return QueryResponse(**result)

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "raisket-rag",
        "version": "1.0.0"
    }

@app.get("/api/sources")
async def list_sources():
    """Lista las fuentes disponibles"""
    return {
        "sources": ["SAT", "CNBV", "Banxico"],
        "namespaces": ["sat", "cnbv", "banxico"]
    }

# ============================================================================
# EJEMPLO DE LLAMADA
# ============================================================================

"""
POST http://localhost:8000/api/query

Body:
{
  "question": "¿Cuáles son los requisitos para deducir arrendamiento?",
  "namespace": "sat",
  "top_k": 5
}

Response:
{
  "answer": "Según la normativa del SAT, para deducir arrendamiento se requiere...",
  "citations": [...],
  "metadata": {
    "sources_count": 3,
    "confidence_overall": 0.89
  }
}
"""
```

---

## 8. IMPLEMENTACIÓN POR FASES

### Fase 1: MVP (Semana 1-2)
```
✓ Pipeline de ingesta básico (PyMuPDF + chunking simple)
✓ Pinecone setup con 3 namespaces (SAT, CNBV, Banxico)
✓ Query pipeline básico (embedding + retrieval + Claude)
✓ FastAPI con endpoint /query
✓ Procesar primeros 10 PDFs más importantes
```

### Fase 2: Optimización (Semana 3)
```
✓ Implementar sistema de citaciones completo
✓ Agregar reranking (BM25 + MMR)
✓ Cache con Redis
✓ Mejorar metadata extraction
✓ Procesar 50 PDFs completos
```

### Fase 3: Producción (Semana 4)
```
✓ Monitoreo y logging
✓ Tests de precisión
✓ Optimización de costos (modelo híbrido)
✓ Documentación de API
✓ Deploy a producción
```

---

## 9. MÉTRICAS DE ÉXITO

```
KPIs Críticos:
├─ Latencia p95: <2 segundos ✓
├─ Precisión: >85% respuestas correctas
├─ Recall de citaciones: >90% citas relevantes incluidas
├─ Costo: <$100/mes para 1K queries ✓
└─ Disponibilidad: >99.5%

Medición de Calidad:
├─ Human evaluation: Sample random 50 queries/semana
├─ Citation accuracy: Verificar que citas sean correctas
├─ Answer relevance: Scoring 1-5 por expertos
└─ User feedback: Thumbs up/down en respuestas
```

---

## 10. PRÓXIMOS PASOS

```
1. Setup inicial (DIA 1)
   - Crear cuenta Pinecone
   - Configurar API keys (OpenAI, Anthropic)
   - Clonar este repo y setup environment

2. Desarrollo (DIA 2-10)
   - Implementar pipeline de ingesta
   - Desarrollar query engine
   - Integrar con FastAPI
   - Testing básico

3. Testing y refinamiento (DIA 11-14)
   - Procesar documentos reales
   - Evaluar calidad de respuestas
   - Optimizar prompts y retrieval
   - Ajustar chunking strategies

4. Producción (DIA 15+)
   - Deploy
   - Monitoring
   - Recolección de feedback
   - Iteración continua
```

---

## RECURSOS ADICIONALES

**Documentación:**
- Pinecone: https://docs.pinecone.io/
- LangChain: https://python.langchain.com/docs/
- Claude API: https://docs.anthropic.com/

**Papers de referencia:**
- "Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks"
- "Lost in the Middle: How Language Models Use Long Contexts"
- "Precise Zero-Shot Dense Retrieval without Relevance Labels"

**Tools recomendadas:**
- LangSmith: Debugging y monitoring de RAG
- Arize Phoenix: Observability para LLM apps
- Ragas: Evaluation framework para RAG systems

---

**Autor:** Claude (Anthropic)
**Fecha:** 2025-10-31
**Versión:** 1.0
**Proyecto:** Raisket MVP
