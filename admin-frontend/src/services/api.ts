import axios from 'axios';
import { Fact } from '../types/fact';

const API_URL = import.meta.env.VITE_API_BASE_URL;

export const api = {
  // Get all facts
  getAllFacts: async () => {
    const response = await axios.get(`${API_URL}/facts`);
    return response.data;
  },

  // Get facts by category
  getFactsByCategory: async (category: string) => {
    const response = await axios.get(`${API_URL}/facts/category/${category}`);
    return response.data;
  },

  // Create a new fact
  createFact: async (fact: Fact) => {
    const response = await axios.post(`${API_URL}/facts`, fact);
    return response.data;
  },

  // Update a fact
  updateFact: async (id: string, fact: Fact) => {
    const response = await axios.put(`${API_URL}/facts/${id}`, fact);
    return response.data;
  },

  // Delete a fact
  deleteFact: async (id: string) => {
    const response = await axios.delete(`${API_URL}/facts/${id}`);
    return response.data;
  },

  // Trigger fact collection
  collectFacts: async () => {
    const response = await axios.post(`${API_URL}/facts/collect`);
    return response.data;
  },
};
