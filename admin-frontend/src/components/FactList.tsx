import React, { useState } from 'react';
import {
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Chip,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import { Edit as EditIcon, Delete as DeleteIcon } from '@mui/icons-material';
import { Fact } from '../types/fact';

interface FactListProps {
  facts: Fact[];
  onEdit: (fact: Fact) => void;
  onDelete: (fact: Fact) => void;
}

export const FactList: React.FC<FactListProps> = ({ facts, onEdit, onDelete }) => {
  const [selectedFact, setSelectedFact] = useState<Fact | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  const handleDeleteClick = (fact: Fact) => {
    setSelectedFact(fact);
    setDeleteDialogOpen(true);
  };

  const handleDeleteConfirm = () => {
    if (selectedFact) {
      onDelete(selectedFact);
      setDeleteDialogOpen(false);
      setSelectedFact(null);
    }
  };

  return (
    <>
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Content</TableCell>
              <TableCell>Category</TableCell>
              <TableCell>Source</TableCell>
              <TableCell>Tags</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {facts.map((fact) => (
              <TableRow key={fact.id}>
                <TableCell>{fact.content}</TableCell>
                <TableCell>{fact.category}</TableCell>
                <TableCell>{fact.source}</TableCell>
                <TableCell>
                  {fact.tags.map((tag) => (
                    <Chip key={tag} label={tag} size="small" style={{ margin: 2 }} />
                  ))}
                </TableCell>
                <TableCell>
                  <IconButton onClick={() => onEdit(fact)} color="primary">
                    <EditIcon />
                  </IconButton>
                  <IconButton onClick={() => handleDeleteClick(fact)} color="error">
                    <DeleteIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Confirm Delete</DialogTitle>
        <DialogContent>
          Are you sure you want to delete this fact?
          <br />
          <br />
          {selectedFact?.content}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleDeleteConfirm} color="error">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};
