var Item = React.createClass({
  getInitialState() {
    return {
      editable: false
    }
  },

  handleDelete() {
    const { item } = this.props
    this.props.handleDelete(item.id)
  },

  handleEdit() {
    const { item } = this.props
    if (this.state.editable) {
      var name = this.refs.name.value
      var description = this.refs.desc.value
      var newItem = {
        id: item.id,
        name,
        description
      }
      this.props.onUpdate(newItem)
    }
    this.setState({editable: !this.state.editable})
  },

  render() {
    const { item } = this.props
    return (
      <div>
        {
          this.state.editable ?
          <input ref="name" defaultValue={item.name}/> :
          <h3>{item.name}</h3>
        }
        {
          this.state.editable ?
          <input ref="desc" defaultValue={item.description}/> :
          <p>{item.description}</p>
        }
        <button onClick={this.handleDelete}>Delete</button>
        <button onClick={this.handleEdit}>{this.state.editable ? 'Submit' : 'Edit'}</button>
      </div>
    )
  }
})