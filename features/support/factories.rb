Factory.define :concept, :class => Iqvoc::Concept.base_class do |c|
  c.sequence(:origin) { |n| "_000000#{n}" }
  c.published_at 3.days.ago
  c.labelings { |labelings| [labelings.association(:pref_labeling)] }
  c.broader_relations { |broader_relations| [broader_relations.association(:broader_relation)]}
  c.narrower_relations{ |narrower_relations| [narrower_relations.association(:narrower_relation)]}
end

Factory.define :broader_relation, :class => Iqvoc::Concept.broader_relation_class do |br|
  br.target { |target|
    target.association(:concept, :broader_relations => [], :narrower_relations => [], :labelings => [
        Factory.create(:pref_labeling, :target => Factory.create(:pref_label, :value => 'Some broader relation'))
      ])
  }
  rel.after_create { |new_relation| Factory(:narrower_relation, :owner => new_relation.target, :target => new_relation.owner) }
end

Factory.define :narrower_relation, :class => Iqvoc::Concept.broader_relation_class.narrower_class do |rel|
  rel.target {|target|
    target.association(:concept, :broader_relations => [], :narrower_relations => [], :labelings => [
        Factory.create(:pref_labeling, :target => Factory.create(:pref_label, :value => 'Some narrower relation'))
      ])
  }
  rel.after_create { |new_relation| Factory(:broader_relation, :owner => new_relation.target, :target => new_relation.owner) }
end

Factory.define :pref_labeling, :class => Iqvoc::Concept.pref_labeling_class do |lab|
  lab.target { |target| target.association(:pref_label) }
end

Factory.define :pref_label, :class => Iqvoc::Concept.pref_labeling_class.label_class do |l|
  l.language Iqvoc::Concept.pref_labeling_languages.first
  l.value 'Tree'
  l.origin 'Tree'
end

Factory.define :xllabel, :class => Iqvoc::XLLabel.base_class do |l|
  l.origin 'Forest'
  l.language 'en'
  l.value 'Forest'
end

Factory.define :xllabel_with_association, :parent => :xllabel do |l|
end

Factory.define :user do |u|
  u.forename 'Test'
  u.surname 'User'
  u.email 'testuser@iqvoc.local'
  u.password 'omgomgomg'
  u.password_confirmation 'omgomgomg'
  u.role 'reader'
  u.active true
end
