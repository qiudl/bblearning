import api from './api';

// 知识点信息
export interface KnowledgePoint {
  id: number;
  name: string;
  grade: number;
  parent_id?: number;
  description?: string;
  difficulty?: string;
  children?: KnowledgePoint[];
}

// 知识点树响应
export interface KnowledgeTreeResponse {
  data: KnowledgePoint[];
}

// 知识点服务
class KnowledgeService {
  /**
   * 获取知识点树
   */
  async getKnowledgeTree(grade?: number): Promise<KnowledgePoint[]> {
    const params = grade ? { grade } : {};
    const response = await api.get('/api/v1/knowledge/tree', { params });
    return response.data || [];
  }

  /**
   * 获取知识点详情
   */
  async getKnowledgePoint(id: number): Promise<KnowledgePoint> {
    const response = await api.get(`/api/v1/knowledge/${id}`);
    return response.data;
  }

  /**
   * 获取所有知识点（扁平列表）
   */
  async getAllKnowledgePoints(grade?: number): Promise<KnowledgePoint[]> {
    const tree = await this.getKnowledgeTree(grade);
    return this.flattenTree(tree);
  }

  /**
   * 将知识点树扁平化
   */
  private flattenTree(nodes: KnowledgePoint[]): KnowledgePoint[] {
    const result: KnowledgePoint[] = [];

    const flatten = (nodes: KnowledgePoint[], level: number = 0) => {
      nodes.forEach(node => {
        result.push({ ...node, level } as any);
        if (node.children && node.children.length > 0) {
          flatten(node.children, level + 1);
        }
      });
    };

    flatten(nodes);
    return result;
  }

  /**
   * 格式化知识点显示名称（带层级缩进）
   */
  formatKnowledgePointName(point: KnowledgePoint & { level?: number }): string {
    const indent = '　'.repeat(point.level || 0);
    return `${indent}${point.name}`;
  }
}

export default new KnowledgeService();
