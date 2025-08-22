import axios from "axios";

// Fonction asynchrone pour lire l'API_URL depuis config.json
export async function getApiUrl(): Promise<string> {
  try {
    const res = await fetch("/config.json");
    if (!res.ok) throw new Error();
    const config = await res.json();
    return config.API_URL || "https://54.82.6.84:8443/api";
  } catch {
    return "https://54.82.6.84:8443/api"; // valeur par défaut si le fichier n'est pas là
  }
}

// Instance Axios sans baseURL initiale
const api = axios.create({
  headers: {
    "Content-Type": "application/json",
  }
});

// Initialisation à faire au démarrage de l'app
export async function initApiBaseUrl() {
  const url = await getApiUrl();
  api.defaults.baseURL = url;
}

export interface Recipe {
  id: number;
  title: string;
  description: string;
  ingredients: string;
  cuisine: string;
  cookingTime: number;
}

export interface UserRequest {
  username: string;
  password: string;
}

export interface PageableObject {
  offset: number;
  pageNumber: number;
  pageSize: number;
  paged: boolean;
  unpaged: boolean;
}

export interface SortObject {
  empty: boolean;
  sorted: boolean;
  unsorted: boolean;
}

export interface PageRecipe {
  content: Recipe[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
  numberOfElements: number;
  first: boolean;
  last: boolean;
  empty: boolean;
  pageable: PageableObject;
  sort: SortObject;
}

export interface RecipeFilters {
  cuisine?: string;
  title?: string;
  ingredients?: string;
  maxCookingTime?: number;
}

export const AuthService = {
  register: async (userData: UserRequest): Promise<any> => {
    const response = await api.post("/auth/register", userData);
    return response.data;
  },

  login: async (userData: UserRequest): Promise<any> => {
    const response = await api.post("/auth/login", userData);
    const { token } = response.data;

    if (token) {
      localStorage.setItem('token', token);
    }

    return response.data;
  },

  logout: (): void => {
    localStorage.removeItem('token');
  },

  isAuthenticated: (): boolean => {
    return !!localStorage.getItem('token');
  }
};

export const RecipeService = {
  getRecipes: async (pageNumber = 0, pageSize = 10): Promise<PageRecipe> => {
    const response = await api.get("/recipes", {
      params: { pageNumber, pageSize }
    });
    return response.data;
  },

  getFilterRecipes: async (filters: RecipeFilters): Promise<Recipe[]> => {
    const response = await api.get("/recipes/filter", {
      params: filters
    });

    return response.data;
  }
}

export default api;