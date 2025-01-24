import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Button,
  Box,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Snackbar,
  Alert,
} from '@mui/material';
import { FactList } from '../components/FactList';
import { FactForm } from '../components/FactForm';
import { api } from '../services/api';
import { Fact, CATEGORIES } from '../types/fact';

export const AdminPage: React.FC = () => {
  const [facts, setFacts] = useState<Fact[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [formOpen, setFormOpen] = useState(false);
  const [selectedFact, setSelectedFact] = useState<Fact | undefined>();
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as const });

  const loadFacts = async () => {
    try {
      let data;
      if (selectedCategory) {
        data = await api.getFactsByCategory(selectedCategory);
      } else {
        data = await api.getAllFacts();
      }
      setFacts(data || []);
    } catch (error) {
      console.error('Error loading facts:', error);
      setSnackbar({
        open: true,
        message: 'Error loading facts',
        severity: 'error',
      });
    }
  };

  useEffect(() => {
    loadFacts();
  }, [selectedCategory]);

  const handleAddNew = () => {
    setSelectedFact(undefined);
    setFormOpen(true);
  };

  const handleEdit = (fact: Fact) => {
    setSelectedFact(fact);
    setFormOpen(true);
  };

  const handleDelete = async (fact: Fact) => {
    try {
      if (fact.id) {
        await api.deleteFact(fact.id);
        setSnackbar({
          open: true,
          message: 'Fact deleted successfully',
          severity: 'success',
        });
        loadFacts();
      }
    } catch (error) {
      console.error('Error deleting fact:', error);
      setSnackbar({
        open: true,
        message: 'Error deleting fact',
        severity: 'error',
      });
    }
  };

  const handleSave = async (fact: Fact) => {
    try {
      if (fact.id) {
        await api.updateFact(fact.id, fact);
        setSnackbar({
          open: true,
          message: 'Fact updated successfully',
          severity: 'success',
        });
      } else {
        await api.createFact(fact);
        setSnackbar({
          open: true,
          message: 'Fact created successfully',
          severity: 'success',
        });
      }
      loadFacts();
    } catch (error) {
      console.error('Error saving fact:', error);
      setSnackbar({
        open: true,
        message: 'Error saving fact',
        severity: 'error',
      });
    }
  };

  const handleCollectFacts = async () => {
    try {
      await api.collectFacts();
      setSnackbar({
        open: true,
        message: 'Fact collection started',
        severity: 'success',
      });
      loadFacts();
    } catch (error) {
      console.error('Error collecting facts:', error);
      setSnackbar({
        open: true,
        message: 'Error collecting facts',
        severity: 'error',
      });
    }
  };

  return (
    <Container maxWidth="xl">
      <Box sx={{ my: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Fact Management
        </Typography>

        <Box sx={{ mb: 2, display: 'flex', gap: 2 }}>
          <FormControl sx={{ minWidth: 200 }}>
            <InputLabel>Category Filter</InputLabel>
            <Select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              label="Category Filter"
            >
              <MenuItem value="">All Categories</MenuItem>
              {CATEGORIES.map((category) => (
                <MenuItem key={category} value={category}>
                  {category}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <Button variant="contained" color="primary" onClick={handleAddNew}>
            Add New Fact
          </Button>

          <Button variant="outlined" color="secondary" onClick={handleCollectFacts}>
            Collect Facts
          </Button>
        </Box>

        <FactList facts={facts} onEdit={handleEdit} onDelete={handleDelete} />

        <FactForm
          open={formOpen}
          onClose={() => setFormOpen(false)}
          onSave={handleSave}
          fact={selectedFact}
        />

        <Snackbar
          open={snackbar.open}
          autoHideDuration={6000}
          onClose={() => setSnackbar({ ...snackbar, open: false })}
        >
          <Alert severity={snackbar.severity}>{snackbar.message}</Alert>
        </Snackbar>
      </Box>
    </Container>
  );
};
