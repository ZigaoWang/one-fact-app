import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Chip,
  Box,
  InputAdornment,
  IconButton,
} from '@mui/material';
import { Add as AddIcon } from '@mui/icons-material';
import { Fact, CATEGORIES, DIFFICULTIES, LANGUAGES } from '../types/fact';

interface FactFormProps {
  open: boolean;
  onClose: () => void;
  onSave: (fact: Fact) => void;
  fact?: Fact;
}

export const FactForm: React.FC<FactFormProps> = ({
  open,
  onClose,
  onSave,
  fact,
}) => {
  const [formData, setFormData] = useState<Fact>({
    content: '',
    source: '',
    category: '',
    tags: [],
    verified: true,
    related_urls: [],
    metadata: {
      language: 'English',
      difficulty: 'Medium',
      references: [],
      keywords: [],
      popularity: 0,
      serve_count: 0,
    },
  });

  const [newTag, setNewTag] = useState('');
  const [newUrl, setNewUrl] = useState('');
  const [newKeyword, setNewKeyword] = useState('');
  const [newReference, setNewReference] = useState('');

  useEffect(() => {
    if (fact) {
      setFormData(fact);
    }
  }, [fact]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleMetadataChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      metadata: {
        ...prev.metadata,
        [name]: value,
      },
    }));
  };

  const handleAddTag = () => {
    if (newTag && !formData.tags.includes(newTag)) {
      setFormData((prev) => ({
        ...prev,
        tags: [...prev.tags, newTag],
      }));
      setNewTag('');
    }
  };

  const handleAddUrl = () => {
    if (newUrl && !formData.related_urls.includes(newUrl)) {
      setFormData((prev) => ({
        ...prev,
        related_urls: [...prev.related_urls, newUrl],
      }));
      setNewUrl('');
    }
  };

  const handleAddKeyword = () => {
    if (newKeyword && !formData.metadata.keywords.includes(newKeyword)) {
      setFormData((prev) => ({
        ...prev,
        metadata: {
          ...prev.metadata,
          keywords: [...prev.metadata.keywords, newKeyword],
        },
      }));
      setNewKeyword('');
    }
  };

  const handleAddReference = () => {
    if (newReference && !formData.metadata.references.includes(newReference)) {
      setFormData((prev) => ({
        ...prev,
        metadata: {
          ...prev.metadata,
          references: [...prev.metadata.references, newReference],
        },
      }));
      setNewReference('');
    }
  };

  const handleSubmit = () => {
    onSave(formData);
    onClose();
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>{fact ? 'Edit Fact' : 'Add New Fact'}</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
          <TextField
            label="Content"
            name="content"
            value={formData.content}
            onChange={handleChange}
            multiline
            rows={4}
            fullWidth
          />

          <FormControl fullWidth>
            <InputLabel>Category</InputLabel>
            <Select
              name="category"
              value={formData.category}
              onChange={(e) => handleChange(e as any)}
              label="Category"
            >
              {CATEGORIES.map((cat) => (
                <MenuItem key={cat} value={cat}>
                  {cat}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <TextField
            label="Source"
            name="source"
            value={formData.source}
            onChange={handleChange}
            fullWidth
          />

          <Box>
            <TextField
              label="Add Tag"
              value={newTag}
              onChange={(e) => setNewTag(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleAddTag()}
              InputProps={{
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton onClick={handleAddTag}>
                      <AddIcon />
                    </IconButton>
                  </InputAdornment>
                ),
              }}
            />
            <Box sx={{ mt: 1 }}>
              {formData.tags.map((tag) => (
                <Chip
                  key={tag}
                  label={tag}
                  onDelete={() =>
                    setFormData((prev) => ({
                      ...prev,
                      tags: prev.tags.filter((t) => t !== tag),
                    }))
                  }
                  sx={{ m: 0.5 }}
                />
              ))}
            </Box>
          </Box>

          <FormControl fullWidth>
            <InputLabel>Language</InputLabel>
            <Select
              name="language"
              value={formData.metadata.language}
              onChange={(e) => handleMetadataChange(e as any)}
              label="Language"
            >
              {LANGUAGES.map((lang) => (
                <MenuItem key={lang} value={lang}>
                  {lang}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <FormControl fullWidth>
            <InputLabel>Difficulty</InputLabel>
            <Select
              name="difficulty"
              value={formData.metadata.difficulty}
              onChange={(e) => handleMetadataChange(e as any)}
              label="Difficulty"
            >
              {DIFFICULTIES.map((diff) => (
                <MenuItem key={diff} value={diff}>
                  {diff}
                </MenuItem>
              ))}
            </Select>
          </FormControl>

          <TextField
            label="Add URL"
            value={newUrl}
            onChange={(e) => setNewUrl(e.target.value)}
            onKeyPress={(e) => e.key === 'Enter' && handleAddUrl()}
            InputProps={{
              endAdornment: (
                <InputAdornment position="end">
                  <IconButton onClick={handleAddUrl}>
                    <AddIcon />
                  </IconButton>
                </InputAdornment>
              ),
            }}
          />
          <Box>
            {formData.related_urls.map((url) => (
              <Chip
                key={url}
                label={url}
                onDelete={() =>
                  setFormData((prev) => ({
                    ...prev,
                    related_urls: prev.related_urls.filter((u) => u !== url),
                  }))
                }
                sx={{ m: 0.5 }}
              />
            ))}
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button onClick={handleSubmit} variant="contained" color="primary">
          Save
        </Button>
      </DialogActions>
    </Dialog>
  );
};
