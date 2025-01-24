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
  AppBar,
  Toolbar,
  TextField,
  Card,
  CardContent,
  Grid,
  IconButton,
  Chip,
  Stack,
  Divider,
  CircularProgress,
} from '@mui/material';
import {
  Add as AddIcon,
  Refresh as RefreshIcon,
  CloudDownload as CloudDownloadIcon,
  Search as SearchIcon,
} from '@mui/icons-material';
import { FactList } from '../components/FactList';
import { FactForm } from '../components/FactForm';
import { api } from '../services/api';
import { Fact, CATEGORIES } from '../types/fact';

export const AdminPage: React.FC = () => {
  const [facts, setFacts] = useState<Fact[]>([]);
  const [filteredFacts, setFilteredFacts] = useState<Fact[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState('');
  const [formOpen, setFormOpen] = useState(false);
  const [selectedFact, setSelectedFact] = useState<Fact | undefined>();
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' as const });
  const [loading, setLoading] = useState(false);
  const [stats, setStats] = useState({
    total: 0,
    verified: 0,
    categories: {} as Record<string, number>,
  });

  const loadFacts = async () => {
    try {
      setLoading(true);
      let data;
      if (selectedCategory) {
        data = await api.getFactsByCategory(selectedCategory);
      } else {
        data = await api.getAllFacts();
      }
      setFacts(data || []);
      updateStats(data);
      filterFacts(data, searchTerm);
    } catch (error) {
      console.error('Error loading facts:', error);
      showError('Error loading facts');
    } finally {
      setLoading(false);
    }
  };

  const updateStats = (factsData: Fact[]) => {
    const stats = {
      total: factsData.length,
      verified: factsData.filter(f => f.verified).length,
      categories: factsData.reduce((acc, fact) => {
        acc[fact.category] = (acc[fact.category] || 0) + 1;
        return acc;
      }, {} as Record<string, number>),
    };
    setStats(stats);
  };

  const filterFacts = (factsData: Fact[], term: string) => {
    const filtered = factsData.filter(fact => 
      fact.content.toLowerCase().includes(term.toLowerCase()) ||
      fact.source.toLowerCase().includes(term.toLowerCase()) ||
      fact.tags.some(tag => tag.toLowerCase().includes(term.toLowerCase()))
    );
    setFilteredFacts(filtered);
  };

  useEffect(() => {
    loadFacts();
  }, [selectedCategory]);

  useEffect(() => {
    filterFacts(facts, searchTerm);
  }, [searchTerm, facts]);

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
        showSuccess('Fact deleted successfully');
        loadFacts();
      }
    } catch (error) {
      console.error('Error deleting fact:', error);
      showError('Error deleting fact');
    }
  };

  const handleSave = async (fact: Fact) => {
    try {
      if (fact.id) {
        await api.updateFact(fact.id, fact);
        showSuccess('Fact updated successfully');
      } else {
        await api.createFact(fact);
        showSuccess('Fact created successfully');
      }
      loadFacts();
    } catch (error) {
      console.error('Error saving fact:', error);
      showError('Error saving fact');
    }
  };

  const handleCollectFacts = async () => {
    try {
      setLoading(true);
      await api.collectFacts();
      showSuccess('Fact collection started');
      setTimeout(loadFacts, 2000); // Reload after 2 seconds
    } catch (error) {
      console.error('Error collecting facts:', error);
      showError('Error collecting facts');
    } finally {
      setLoading(false);
    }
  };

  const showSuccess = (message: string) => {
    setSnackbar({ open: true, message, severity: 'success' });
  };

  const showError = (message: string) => {
    setSnackbar({ open: true, message, severity: 'error' });
  };

  return (
    <Box>
      <AppBar position="static" elevation={0}>
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            One Fact Admin
          </Typography>
          <Button 
            color="inherit" 
            startIcon={<CloudDownloadIcon />}
            onClick={handleCollectFacts}
            disabled={loading}
          >
            Collect Facts
          </Button>
        </Toolbar>
      </AppBar>

      <Container maxWidth="xl" sx={{ mt: 4 }}>
        {/* Stats Cards */}
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" color="text.secondary">Total Facts</Typography>
                <Typography variant="h3">{stats.total}</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" color="text.secondary">Verified Facts</Typography>
                <Typography variant="h3">{stats.verified}</Typography>
              </CardContent>
            </Card>
          </Grid>
          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" color="text.secondary">Categories</Typography>
                <Typography variant="h3">{Object.keys(stats.categories).length}</Typography>
              </CardContent>
            </Card>
          </Grid>
        </Grid>

        {/* Filters and Actions */}
        <Box sx={{ mb: 4 }}>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                label="Search Facts"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon color="action" sx={{ mr: 1 }} />,
                }}
              />
            </Grid>
            <Grid item xs={12} md={4}>
              <FormControl fullWidth>
                <InputLabel>Category Filter</InputLabel>
                <Select
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  label="Category Filter"
                >
                  <MenuItem value="">All Categories</MenuItem>
                  {CATEGORIES.map((category) => (
                    <MenuItem key={category} value={category}>
                      {category} {stats.categories[category] ? `(${stats.categories[category]})` : ''}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={4}>
              <Stack direction="row" spacing={2} justifyContent="flex-end">
                <Button
                  variant="contained"
                  startIcon={<AddIcon />}
                  onClick={handleAddNew}
                >
                  Add New Fact
                </Button>
                <Button
                  variant="outlined"
                  startIcon={<RefreshIcon />}
                  onClick={loadFacts}
                  disabled={loading}
                >
                  Refresh
                </Button>
              </Stack>
            </Grid>
          </Grid>
        </Box>

        {/* Category Chips */}
        <Box sx={{ mb: 3 }}>
          <Stack direction="row" spacing={1} flexWrap="wrap" gap={1}>
            {Object.entries(stats.categories).map(([category, count]) => (
              <Chip
                key={category}
                label={`${category} (${count})`}
                onClick={() => setSelectedCategory(category)}
                onDelete={selectedCategory === category ? () => setSelectedCategory('') : undefined}
                color={selectedCategory === category ? 'primary' : 'default'}
              />
            ))}
          </Stack>
        </Box>

        {/* Facts Table */}
        {loading ? (
          <Box sx={{ display: 'flex', justifyContent: 'center', my: 4 }}>
            <CircularProgress />
          </Box>
        ) : (
          <FactList facts={filteredFacts} onEdit={handleEdit} onDelete={handleDelete} />
        )}

        {/* Fact Form Dialog */}
        <FactForm
          open={formOpen}
          onClose={() => setFormOpen(false)}
          onSave={handleSave}
          fact={selectedFact}
        />

        {/* Snackbar for notifications */}
        <Snackbar
          open={snackbar.open}
          autoHideDuration={6000}
          onClose={() => setSnackbar({ ...snackbar, open: false })}
          anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        >
          <Alert severity={snackbar.severity} variant="filled">
            {snackbar.message}
          </Alert>
        </Snackbar>
      </Container>
    </Box>
  );
};
